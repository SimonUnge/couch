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
  if (notification_type(notification) == "save/update") #XXX not good to get non-existing doc. Want to remove
    #puts "Here we go, getting the doc:"
    doc = get_doc(get_doc_id(result))
    #puts doc
    job_arr = get_job_arr(doc)
    step = get_step(doc)
    if step < job_arr.length  
      job = get_job(job_arr, step)
      if target_any?(job, db)      #CHANGE NAME DAMN IT, FROM DB TO NODE XXXX
        claim_or_work(job, db, doc)
      elsif my_job?(job, db)
        system(job["do"])
        set_step(doc)
        while next_is_mine?(job_arr, db, get_step(doc)) do
          system(job["do"])
          set_step(doc)
        end
        save_doc(doc)
      end
    end
  end
end

def claim_or_work(job, db, doc)
  if !has_winner?(job)          # if no winner is selected
    puts "#{db} will try to claim #{job}"
    if !has_been_claimed?(job)  # and if no one has claimed it. XXX SAMMA RAD?
      set_claim(job, db)
      save_doc(doc)
    else
      coord_set_winner(job, db, doc)
    end
  elsif is_winner?(job, db)
    system(job["do"])
    set_step(doc)
    save_doc(doc)
  end 
end

def save_doc(doc)
  begin
    DB.save_doc(doc)
  rescue RestClient::Conflict
    puts "Save Conflict, No problem tho, thanks to couchDB<-----------------------"
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
  if job != nil
    job["target"] == db #XXX Ugly, but to see if job is for just me
  else
    false
  end
end

def next_is_mine?(job_arr, db, next_step)
  next_job = get_job(job_arr, next_step)
  my_job?(next_job, db)
end

def target_any?(job, db)
  job["target"] == "any"
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

def get_claim(job)
  job("claimed_by")
end

#SETTERS

def set_claim(job, node_id)
  job["claimed_by"] = node_id
end

def set_step(doc)
  doc["step"] += 1
end

def coord_set_winner(job, db, doc)
  coordinator = "global_node"
  if db == coordinator
    job["winner"] = job["claimed_by"]
    save_doc(doc)
  end
end

start_continuous_changes('127.0.0.1', port, node)