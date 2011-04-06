GLOHOST=http://127.0.0.1:5001
REG1HOST=http://127.0.0.1:5002
REG2HOST=http://127.0.0.1:5003

GLO_LOCAL=global_node
REG_LOCAL=reg_node

GLO_DB="$GLOHOST/$GLO_LOCAL"
REG_DB1="$REG1HOST/$REG_LOCAL"
REG_DB2="$REG2HOST/$REG_LOCAL"

curl -X POST $GLOHOST/_replicate -d '{"source":"$REG_DB1", "target":"$GLO_LOCAL", "continuous:true"}'
curl -H "Content-Type: application/json" -X POST "$GLOHOST/_replicate" -d "{\"source\":\"$REG_DB2\", \"target\":\"$GLO_LOCAL\", \"continuous:true\"}"


curl -H "Content-Type: application/json" -X POST "$REG1HOST/_replicate" -d "{\"source\":\"$GLO_DB\", \"target\":\"$REG_LOCAL\", \"continuous:true\"}"
curl -H "Content-Type: application/json" -X POST "$REG2HOST/_replicate" -d "{\"source\":\"$GLO_DB\", \"target\":\"$REG_LOCAL\", \"continuous:true\"}"
