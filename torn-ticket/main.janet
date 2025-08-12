## https://github.com/good-place/chidi/blob/e5921eba7ed845c5664c34611bf3c727daf7a9c2/chd argparse example
## https://janet.zulipchat.com/#narrow/channel/409517-help/topic/.E2.9C.94.20.60let.60.20macro/with/472020285 destruct match

(import spork/argparse)
(import jurl)
(import spork/json)
########################INFO#########################################
# This script requires api key, start- and endtime in epoch unix time.
#
# Each chainreport contains a unix time start- and endpoint.
# These variables are available from the Torn's api v2, "https://api.torn.com/v2/faction/{chainId}/chainreport?key={api}".
# chainId is available through api or from link to the chain report available on the faction page.
# Api key is a personal generated key. This api requires a public access key.
#
# Chain hits can be gathered from "https://api.torn.com/v2/faction/attacks?limit={query limit}&sort={ASC or DESC}&to={endPoint}&from={startTime}key={api}".
# This api endpoint will give faction detailed attack logs.

## Script needs to check who is the attacker in the logs.
## The logs contains players attacking HT also.
########################INFO#########################################


## Global Constants ##
(def maxHits 25000)
(def addUnixEpocSeconds 330) ## "https://api.torn.com/v2/faction/{chainId}/chainreport?key={api}" does not count the bonus hit in report if(?) it's the first time the faction hit's the bonus(?).
                            ## Value 300 is added to end time from chainreport. 330 = 5.5 minuts.
(def factionId 9524)
(def resultTable @{})
## Global Variables
(var nextLink nil)
## Correct args-params
(def arg-params
  [(string "Generate csv from chainreport containing username and chain hit number\n"
           "Usage: janet torn-ticket.janet -a torn-api-key -s epoch-start-time -e epoch-end-time")
   "api-key" {:kind :option
                :short "a"
              :required true
              :help "Api-key from torn"}
   "start-time" {:kind :option
                   :short "s"
                 :required true
                 :help "Unix epoch start time"}
   "end-time" {:kind :option
                 :short "e"
               :required true
               :help "Unix epoch end time"}])

## Test arg-params
(def arg-params-test
  [(string "TMP: Generate csv from chainreport containing username and chain hit number\n"
           "Usage: janet torn-ticket.janet -t test-data")
   "test-data" {:kind :option
                :short "t"
              :required true
                :help "Test data file that should be worked on"}
  "api-key" {:kind :option
                :short "a"
              :required true
              :help "Api-key from torn"}])



(defn map-attacks-tables [attacks-table]
   (var
    {"id" attack-id
     "code" attack-code
     "started" attack-started
     "ended" attack-ended
     "attacker" attack-attacker
     "defender" attack-defender
     "result" attack-result
     "respect_gain" attack-respect_gain
     "respect_loss" attack-respect_loss
     "chain" attack-chain
     "is_interrupted" attack-is_interrupted
     "is_stealthed" attack-is_stealthed
     "is_raid" attack-is_raid
     "is_ranked_war" attack-is_ranked_war
     "modifiers" attack-modifiers
    "finishing_hit_effects" attack-finishing_hit_effects} attacks-table)
  (case (type attack-attacker)
    :table (do
             (var
              {"id" attack-attacker-id
               "name" attack-attacker-name
               "level" attack-attacker-level
               "faction" attack-attacker-faction} attack-attacker)
             (case (type attack-attacker-faction)
               :table (do
                        (var
                         {"id" attack-attacker-faction-id
                          "name" attack-attacker-faction-name} attack-attacker-faction)
                        (if (> attack-chain 0)
                          (if (= attack-attacker-faction-id factionId)
                            (put resultTable attack-chain attack-attacker-name)))))
             )))

(defn getData-test
  [test-data api]
  (pp api)
  (var tmpData (json/decode (slurp test-data)))        # Decode json into janet data structuress.
  (var tmpData_metadata (tmpData "_metadata"))         # Destruct toplevel table.
  (var tmpData_links (tmpData_metadata "links"))       # Destruct table.
  (var tmpData_next (tmpData_links "next"))            # Destruct table and get wanted next link.
  (var tmpData_attacks (tmpData "attacks"))            # Destruct toplevel table
  (pp tmpData_metadata)
  (pp tmpData_links)
  (print tmpData_next)
  #(print tmpData_attacks)
  #(pp (in tmpData_attacks 1))
  (map map-attacks-tables tmpData_attacks)
#  (map pp tmpData_attacks)
#  (var tmpData_attack (tmpData_attacks "attacker"))
#  (print tmpData_attacks)
  (pp resultTable)
  (set nextLink (string tmpData_next "&key=" api))
  (pp nextLink)
)


(defn getData
  [api startT endT]
#  (pp api)
 # (pp startT)
 # (pp endT)
  (var api-string (string "https://api.torn.com/v2/faction/attacks?limit=100&sort=ASC&to=" endT "&from=" startT "&key=" api))
#  (pp api-string)
  (var data (jurl/slurp api-string))

  (var tmpData (json/decode data))        # Decode json into janet data structuress.
  (var tmpData_metadata (tmpData "_metadata"))         # Destruct toplevel table.
  (var tmpData_links (tmpData_metadata "links"))       # Destruct table.
  (var tmpData_next (tmpData_links "next"))            # Destruct table and get wanted next link.
  (var tmpData_attacks (tmpData "attacks"))            # Destruct toplevel table
#  (pp tmpData_metadata)
#  (pp tmpData_links)
#  (print tmpData_next)
  (map map-attacks-tables tmpData_attacks)
#  (pp resultTable)
  (set nextLink (string tmpData_next "&key=" api))
  (pp nextLink)
  (var oldLink nil)
  (while (not= nil nextLink)
    (set oldLink nextLink)
    (var dataNext (jurl/slurp nextLink))
    (var tmpData (json/decode dataNext))        # Decode json into janet data structuress.
    (var tmpData_metadata (tmpData "_metadata"))         # Destruct toplevel table.
    (var tmpData_links (tmpData_metadata "links"))       # Destruct table.
    (var tmpData_next (tmpData_links "next"))            # Destruct table and get wanted next link.
    (var tmpData_attacks (tmpData "attacks"))            # Destruct toplevel table
    #  (pp tmpData_metadata)
    #  (pp tmpData_links)
    #  (print tmpData_next)
    (map map-attacks-tables tmpData_attacks)
    #  (pp resultTable)

    (set nextLink (string tmpData_next "&key=" api))
    (pp nextLink)
    (print (length resultTable))
    (if (= oldLink nextLink)
      (set nextLink nil))
    (os/sleep 5)
    )
  (spit "./test-table.txt" (string "Chain number:Username" "\n") :a)
  (loop [[chainNumber username] :in (pairs resultTable)]
    (spit "./test-table.txt" (string chainNumber ":" username "\n") :a)
    )
  # (var data (string "https://api.torn.com/v2/faction/attacks?limit=100&sort=ASC&to=" endT "&from=" startT "key="api))
#  (pp data)
#(spit "./test-string.txt" data)


  )


## Correct main.
 (defn main
   [&]
   (def res (argparse/argparse ;arg-params))
   (if res
     (getData (get res "api-key") (get res "start-time") (get res "end-time"))
     (os/exit 1))
   )

## Working on parsing main with test data.
#(defn main
#  [&]
#  (def res (argparse/argparse ;arg-params-test))
#  (if res
#    (getData-test (get res "test-data") (get res "api-key"))
#    (os/exit 1))
#)

