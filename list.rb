require 'rubygems'
require 'couchrest'
require 'net/http'

puts "Port # of host:"
port = gets.chop
puts "database name:"
node = gets.chop

SERVER = CouchRest.new("127.0.0.1:" << port)
DB = SERVER.database(node)

def handle_notification(notification, db)
  result = JSON.parse(notification)
  #puts result
  if (notification_type(notification) == "save/update") #XXX not good to get non-existing doc.
    #puts "Here we go, getting the doc:"
    doc = get_doc(get_doc_id(result))
    #puts doc
    job_arr = get_job_arr(doc) #Getting the key job, which, for now, is an array.
    step = get_step(doc)
    #sleep(rand(5))
    if step < job_arr.length  
      job = get_job(job_arr, step)
      if my_job?(job, db)      #CHANGE NAME DAMN IT, FROM DB TO NODE XXXX
        if !has_winner?(job)          # if no winner is selected
          puts "I will try to claim#{db}"
          if !has_been_claimed?(job)  # and if no one has claimed it. XXX SAMMA RAD?
            set_claim(job, db)
            save_doc(doc)
          end
        elsif is_winner?(job, db)
          system(job["do"])
          set_step(doc)
          save_doc(doc)
        end
      end
    end
  end
end

def save_doc(doc)
  begin
    DB.save_doc(doc)
  rescue RestClient::Conflict
  end
end

#Starts cont changes.
def start_continuous_changes(host, port, db, heartbeat = '1000')
  path = '/' << db << '/_changes?feed=continuous&heartbeat=' << heartbeat
  Net::HTTP.get_response(host, path, port) do |response|
    response.read_body do |notification|
      if notification?(notification)          #Due to heartbeat, it's a newline instead of notification.  
        handle_notification(notification, db) #Hopefully, I do not need to work with start_cont_changes any more.
      end
    end
  end
end

#CHECKERS
def notification?(notification)
  (notification != "\n")
end

def notification_type(notification)
  if notification["deleted"]
    "deleted"
  else
    "save/update"
  end
end

def affects_me?(doc, db)
  doc["node"] == db || doc["node"] == "all_nodes"
end

def my_job?(job, db)
  job["target"] == db || job["target"] == "any" #XXX Ugly, but to see if job is for just me
end

def has_winner?(job)
  job["winner"] != nil
end

def is_winner?(job, node_id)
  job["winner"] == node_id
end

def has_been_claimed?(job)
  job["claimed_by"] != nil
end

def has_claimed?(job, node_id)
  job["claimed_by"] == node_id
end

#GETTERS
#Get the document "did".
def get_doc(did)
  DB.get(did)
end

#Returns the ID och the document.
def get_doc_id(notification)
  notification["id"]
end

def get_job_arr(doc)
  doc["job"]
end

def get_job(job_arr, step)
  job_arr[step]
end

def get_num_jobs(job_arr)
  job_arr.length
end

def get_winner(job)
  job["winner"]
end

def get_step(doc)
  doc["step"]
end

#SETTERS

def set_claim(job, node_id)
  job["claimed_by"] = node_id
end

def set_step(doc)
  doc["step"] += 1
end


start_continuous_changes('127.0.0.1', port, node)