require 'tweakSiri'
require 'siriObjectGenerator'

class TestProxy < SiriPlugin

	def initialize()
		@state = :DEFAULT_STATE
		@execution = :NOTHING

	end

	def object_from_guzzoni(object, connection) 
		
		object
	end
		
	def object_from_client(object, connection)
		object
	end
	
	def generate_custom_response(refId, text="")
		object = SiriAddViews.new
		object.make_root(refId)

		answer = SiriAnswer.new("Request", [
			SiriAnswerLine.new(text)
		])
		confirmationOptions = SiriConfirmationOptions.new(
			[SiriSendCommands.new([SiriConfirmSnippetCommand.new(),SiriStartRequest.new("yes",false,true)])],
			[SiriSendCommands.new([SiriCancelSnippetCommand.new(),SiriStartRequest.new("no",false,true)])],
			[SiriSendCommands.new([SiriCancelSnippetCommand.new(),SiriStartRequest.new("no",false,true)])],
			[SiriSendCommands.new([SiriConfirmSnippetCommand.new(),SiriStartRequest.new("yes",false,true)])]
		)
		
		if(text == "open") 
			@execution = :ITUNES
		elsif(text == "browser") 
			@execution = :SAFARI
		else
			@execution = :OTHER
		end
		
		
		
		object.views << SiriAssistantUtteranceView.new("Here is your request:", "Here is your request. Ready to execute?", "Misc#ident", true)
		object.views << SiriAnswerSnippet.new([answer], confirmationOptions)

		object.to_hash
	end
	
	def unknown_command(object, connection, command)
		
		if(command.match(/^do (.+)/i))
			self.plugin_manager.block_rest_of_session_from_server
				@state = :CONFIRM_STATE
				@tweetText = $1
				return self.generate_custom_response(connection.lastRefId, $1);
		end
		
		object
	end
	
	def speech_recognized(object, connection, phrase)
	
		if (@state == :CONFIRM_STATE)
			if phrase.match(/yes/i)
				self.plugin_manager.block_rest_of_session_from_server
				if (@execution == :ITUNES)
					response = %x[open /Applications/iTunes.app]
				elsif (@execution == :SAFARI)
					response = %x[open /Applications/Safari.app]
				end
				@state = :DEFAULT_STATE
				@execution = :NOTHING
				return generate_siri_utterance(connection.lastRefId, "Job Done")
				end
		end
		
		
		if(phrase.match(/good morning/i))
			self.plugin_manager.block_rest_of_session_from_server
			return generate_siri_utterance(connection.lastRefId, "Good morning, Dave!")
		end	
		
		object
	end
	
end 