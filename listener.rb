require 'rubygems'
require 'couchrest'
require 'net/http'

SERVER = CouchRest.new("127.0.0.1:5001")
DB = SERVER.database("global_node")
#@DB = "127.0.0.1:5001/global_node"

##GETTERS

#Get the changes for the database, using polling for now, resulting in a
#a hash with two(?) key: "results" and "last_seq"


def get_changes
    CouchRest.get(SERVER.uri << DB.uri << "/_changes")
end

#Starts cont changes and prints json string of notification.
def start_continuous_changes(host, port, db, heartbeat = '1000')
    Net::HTTP.get_response(host, db << '/_changes?feed=continuous&heartbeat=' << heartbeat, port) do |response|
        response.read_body do |notification|
            if notification?(notification)          #Due to heartbeat, it's a newline instead of notification.  
                result = JSON.parse(notification)
                puts result
                if (notification_type(notification) == "save/update") #not good to get non-existing doc.
                    puts "Here we go, getting the doc:"
                    doc = get_doc(get_doc_id(result))
                    puts doc
                    if affects_me?(doc)
                        puts "YES, IT DID!"
                    else
                        puts "nah, it was for #{doc["node"]}"
                    end
                end
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

def affects_me?(doc)
    doc["node"] == "global_node"
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

start_continuous_changes('127.0.0.1', 5001, '/global_node')
