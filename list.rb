require 'rubygems'
require 'couchrest'
require 'net/http'

puts "Port # of host:"
port = gets.chop
puts "database name:"
node = gets.chop

SERVER = CouchRest.new("127.0.0.1:" << port)
DB = SERVER.database(node)

##GETTERS

#Get the changes for the database, using polling for now, resulting in a
#a hash with two(?) key: "results" and "last_seq"

def get_changes
  CouhRest.get(SERVER.uri << DB.uri << "/_changes")
end

def handle_notification(notification, db)
  result = JSON.parse(notification)
  puts result
  if (notification_type(notification) == "save/update") #XXX not good to get non-existing doc.
    puts "Here we go, getting the doc:"
    doc = get_doc(get_doc_id(result))
    puts doc
    jobs = get_job(doc) #Getting the key job, which, for now, is an array.
    jobs.each do |job| 
      if my_job(job, db) #The job could be for this node, or other.
        system(job[db])  #Shell call
        sleep(1)
      end
    end
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

def get_last_seq(changes)
  changes["last_seq"]
end

def get_result_array(changes)
  changes["results"]
end

def get_hash_key_match(key, match, array)
  array.find do |hash|
    hash[key] == match
  end
end

#Get the document "did".
def get_doc(did)
  DB.get(did)
end

def get_job(doc)
  doc["job"]
end

def my_job(job, db)
  job.has_key?(db)
end

def get_doc_from_changes(doc, changes)
  result_array = get_result_array(changes)
  doc_hash = get_hash_key_match("id", doc, result_array)
end

def latest_change(changes)
  result_arr = get_result_array(changes)
  result_arr[-1]
end

def get_doc_id(notification)
  notification["id"]
end

start_continuous_changes('127.0.0.1', port, node)