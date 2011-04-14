require 'rubygems'
require 'daemons'

@num = 5
def worker()
  loop do
    task = get_task()
    perform_task(task)
  end
end

def get_task
  "ping -c 1 localhost"
end

def perform_task(task)
  system(task)
end

options = {:multiple => true, :monitor => true, :log_output => true}

puts "before"

Daemons.run('worker.rb',options)

puts "Guess I wont get here"
# while task1.running? && task2.running? do
#   @num = @num - 1
#   puts @num
#   if @num == 0
#     Daemons.group.stop_all(true)
#   end
#   task1.show_status
#   task2.show_status
# end
