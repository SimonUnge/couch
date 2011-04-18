
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
  gets.chop
end

def perform_task(task)
  system(task)
end

options = {:multiple => true, :monitor => true, :log_output => true}

puts "before"

#Daemons.run('worker.rb',options)

task = Daemons.call(:multiple => true) do
  loop do
  end
end

puts "after"
