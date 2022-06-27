#! /bin/bash

# Defining function to print error or success message

print_message() {
    type=$1
    message=$2
    if [ $type == "error" ]; then
        echo -e "\e[31m$message\e[0m" 
    else
        echo -e "\e[32m$message\e[0m"
    fi
}

save_report() {

    report_file=$1
    status=$2
    output_file="${report_file/STATUS_NA/"STATUS_$status"}"
    mv $report_file $output_file
}

NODE_VERSION=$(node --version)

declare -a NODE_COMMANDS=("npm") # Default ("yarn" "npm") 

echo "Starting compatibily test"

readarray -t repoArrays < <(jq -c '.repositories[]' repositories.json) # Reads the repositories from the json file 

for repo in "${repoArrays[@]}"; do

   #echo '=============================' >> reports/log.txt
   #echo '*** *** *** START *** *** ***' >> reports/log.txt
   #echo ' ' >> reports/log.txt

   repoURL=$(echo $repo | jq '.repoURL' | sed 's/\"//g') # Cleaning the repoURL JSON output
   repoDir=$(basename $repoURL .git) # Getting the repo directory name

   #sshot_name="${repoDir}-${command}-node-${NODE_VERSION}-chrome.png"
   #sshot_name="screen.png"

   echo "Cloning $repoURL"
   if git clone $repoURL; then
     echo "Cloned $repoURL"             # >> reports/log.txt
   else
     echo "Failed to clone $repoURL"    # >> reports/log.txt
     echo ' '                           # >> reports/log.txt
     echo "END test, STATUS= FAILED"    # >> reports/log.txt
     exit 1
     #continue
   fi

   # Accessing the cloned repository directory
   cd $(basename $repoURL .git)
    
   # Using node commands: npm and yarn

   for command in "${NODE_COMMANDS[@]}"; do

      # Build SSHot and report file name
      
      report_file=../reports/"${repoDir}-${command}-node-${NODE_VERSION}-STATUS_NA.log"
      report_sshot="${repoDir}-${command}-node-${NODE_VERSION}-sshot.png"

      echo ' -> ${command} TESTS'                                      >> $report_file
      echo " Testing ${repoDir} / ${command} / NodeJS.${NODE_VERSION}" >> $report_file 
      echo ' '                                                         >> $report_file

      save_report $report_file OK 
      exit 0  

      PIPELINE_ERROR_MESSAGE="Node version $NODE_VERSION, $command -> failed"
      NPM_STATUS=False
      YARN_STATUS=False

      echo "Installing dependencies with $command"
        if $command install; then
            echo " > success Installed $command"          # >> ../reports/log.txt
        else
            echo " > error Installation failed $command"  # >> ../reports/log.txt
            echo " > error $PIPELINE_ERROR_MESSAGE"       # >> ../reports/log.txt 
            echo ' '                                      # >> ../reports/log.txt
            echo "END test, STATUS= FAILED"               # >> ../reports/log.txt
            #exit 1
            continue
        fi
      echo " > Running test with $command"
        if CI=true $command test --passWithNoTests; then
            echo " >  success Tests passed $command"      # >> ../reports/log.txt
        else
            echo " > error Tests failed $command"         # >> ../reports/log.txt
            echo " > error $PIPELINE_ERROR_MESSAGE"       # >> ../reports/log.txt 
            echo ' '                                      # >> ../reports/log.txt
            echo "END test, STATUS= FAILED"               # >> ../reports/log.txt            
            #exit 1
            continue
        fi
      echo "Running build with $command"
        if [ "$command" = "npm" ]; then
            if $command run build; then
                echo " > success Built $command"          # >> ../reports/log.txt 
            else
                echo " > error Build failed $command"     # >> ../reports/log.txt  
                echo " > error $PIPELINE_ERROR_MESSAGE"   # >> ../reports/log.txt 
                echo ' '                                  # >> ../reports/log.txt
                echo " > END test, STATUS= FAILED"        # >> ../reports/log.txt 
                #exit 1
                continue
            fi
        else 
            if $command build; then
                echo " > success Built $command"          # >> ../reports/log.txt 
            else
                echo " > error Build failed $command"     # >> ../reports/log.txt 
                echo " > error $PIPELINE_ERROR_MESSAGE"   # >> ../reports/log.txt 
                echo ' '                                  # >> ../reports/log.txt
                echo " > END test, STATUS= FAILED"        # >> ../reports/log.txt
                #exit 1
                continue
            fi
        fi

        if [ "$command" = "npm" ]; then
            npm i -g serve
        else
            yarn add serve
        fi

        echo "Starting APP in browser"                            # >> ../reports/log.txt 
        if serve -s build & 
        then
            echo " > Serving application with $command"           # >> reports/log.txt

            chromium-browser --headless --screenshot=$report_sshot "http://localhost:3000"
            mv $report_sshot ../reports/

            echo " > Saving SSHot -> $report_sshot"                 # >> ../reports/log.txt

            # not working    
            #echo "test body" | mail -s 'test subject' chirilovadrian@gmail.com 

        else
            echo " > error $repoDir Starting APP failed $command" # >> ../reports/log.txt   
            echo " > error $PIPELINE_ERROR_MESSAGE"               # >> ../reports/log.txt 
            echo ' '                                              # >> ../reports/log.txt
            echo " > END test, STATUS = FAILED"                   # >> ../reports/log.txt
            #exit 1
            continue
        fi

        killall -9 node
        echo "END test, STATUS= OK"                               # >> ../reports/log.txt        

    done

    # Iterate on the next REPO    
    cd ..

 done 