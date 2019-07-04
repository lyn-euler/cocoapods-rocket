require 'colored2'
require 'fileutils'

class Pod::Command::Rocket
  module Utility
    class Scanner

      def self.ask(question, default_answer = nil)
        answer = ""
        loop do
          puts "\n#{question}"

          show_prompt
          answer = STDIN.gets.chomp
          if answer.length == 0
            answer = default_answer unless default_answer.nil?
          end

          break if answer.length > 0

          print "\nYou need to provide an answer."
        end
        answer
      end

      def self.ask_with_answers(question, possible_answers)

        print "\n#{question}? ["

        print_info = Proc.new {

          possible_answers_string = possible_answers.each_with_index do |answer, i|
            _answer = (i == 0) ? answer.underlined : answer
            print " " + _answer
            print(" /") if i != possible_answers.length-1
          end
          print " ]\n"
        }
        print_info.call

        answer = ""

        loop do
          show_prompt
          answer = STDIN.gets.downcase.chomp

          answer = "yes" if answer == "y"
          answer = "no" if answer == "n"

          # default to first answer
          if answer == ""
            answer = possible_answers[0].downcase
            print answer.yellow
          end

          break if possible_answers.map { |a| a.downcase }.include? answer

          print "\nPossible answers are ["
          print_info.call
        end

        answer
      end

      private
      def self.show_prompt
        print " > ".green
      end
    end
  end
end
