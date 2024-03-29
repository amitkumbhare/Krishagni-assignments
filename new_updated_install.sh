#!/bin/bash

PROPERTY_FILE=$1

ensurePropsFileSpecified() {
  if [ -z "$PROPERTY_FILE" ]; then
    echo "Error: Please specify the absolute path of OpenSpecimen deployment properties file.";
    echo "Usage: install.sh <absolute-path-to-properties-file>";
    exit 1;
  fi
}

initVariables() {
  WAR_NAME=$(cat $PROPERTY_FILE | grep "^app.name=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$WAR_NAME" ]; then
    echo "Error: App name not specified. Please specify the value for app.name in $PROPERTY_FILE";
    exit 1;
  fi
  
  TOMCAT_PATH=$(cat $PROPERTY_FILE | grep "^tomcat.dir=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$TOMCAT_PATH" ]; then
    echo "Error: Tomcat home directory path is not specified. Please specify the value for tomcat.dir in $PROPERTY_FILE";
    exit 1;
  fi
  
  if [ ! -f "$TOMCAT_PATH/bin/startup.sh" ]; then
    echo "Error: $TOMCAT_PATH doesn't appear to be the Tomcat home directory.";
    exit 1;
  fi
  
  OS_DATA_DIR=$(cat $PROPERTY_FILE | grep "^app.data_dir=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$OS_DATA_DIR" ]; then
    echo "Error: OS data directory path is not specified. Please specify the value for app.data_dir in $PROPERTY_FILE";
    exit 1;
  fi
  
  OS_PLUGIN_DIR=$(cat $PROPERTY_FILE | grep "^plugin.dir=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$OS_PLUGIN_DIR" ]; then
    echo "Error: OS plugins directory path is not specified. Please specify the value for plugin.dir in $PROPERTY_FILE";
    exit 1;
  fi
  
  DATABASE_TYPE=$(cat $PROPERTY_FILE | grep "^database.type=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$DATABASE_TYPE" ]; then
    echo "Error: Database type is not specified. Please specify the value for database.type in $PROPERTY_FILE";
    echo "The valid values for database.type are mysql and oracle";
    exit 1;
  fi
  
  DATASOURCE_JNDI=$(cat $PROPERTY_FILE | grep "^datasource.jndi=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$DATASOURCE_JNDI" ]; then
    echo "Error: Tomcat data source name is not specified. Please specify the value for datasource.jndi in $PROPERTY_FILE";
    echo "The value for datasource.jndi will be same as the data source JNDI name configured in $TOMCAT_PATH/conf/context.xml";
    exit 1;
  fi
  
  DATASOURCE_TYPE=$(cat $PROPERTY_FILE | grep "^datasource.type=" | cut -d'=' -f2 | sed 's/ //g');
  if [ -z "$DATASOURCE_TYPE" ]; then
    echo "Error: Database schema type is not specified. Please specify the value for datasource.type in $PROPERTY_FILE";
    echo "The valid values for datasource.type are fresh and upgrade";
    exit 1;
  fi
  
  BACKUP_DIR=$(date '+%d%m%Y_%H%M%S');
}

ensurePrerequisites() {
  javaversion=$(java -version 2>&1 | grep -i version | awk '{print $3}' | cut -d'"' -f2 | cut -d'.' -f1)
 
  if [ "$javaversion" == "17" ]; then
    echo "Java version check...pass"
  else
    echo "Install java 17 to proceed with installation."
    exit 1
  fi
  read -p "Is MySQL server installed on the same machine? If no, please make sure MySQL 5.7 version is installed on the remote database server (y/n):" input

  if [ "$input" == "y" ]; then
    if [[ "$DATABASE_TYPE" == "mysql" ]]; then
      mysql --version 2>&1 | grep "5.7"
      rc=$?;
      if [[ $rc == 0 ]]; then
        echo "MySQL version check...pass";
      else
        echo "Need to install MySQL 5.7 to proceed with installation.";
        exit 1;
      fi
    fi
  fi

  tomcatversion=`$TOMCAT_PATH/bin/./version.sh | grep "Server version"  | cut -d'/' -f2 | cut -d'.' -f1`
  if [[ $tomcatversion == 9 ]]; then
    echo "Tomcat version check...pass";
  else
    echo "Install Tomcat 9 from build zip to proceed with installation.";
    exit 1;
  fi
}

ensureDataAndPluginDirsExist() {
  if [ ! -d "$OS_PLUGIN_DIR" ]; then
    mkdir -p $OS_PLUGIN_DIR
    rc=$?;
    if [[ $rc != 0 ]]; then
      echo "Error: Could not create the plugins directory $OS_PLUGIN_DIR. Please ensure you've appropriate rights to create the directory.";
      exit $rc;
    fi
  fi

  if [ -d "$OS_PLUGIN_DIR" ]; then
    touch  $OS_PLUGIN_DIR/test.txt
    rc=$?;
    rm $OS_PLUGIN_DIR/test.txt
    
    if [[ $rc != 0 ]]; then
      echo "Error: Do not have write permissions on the directory $OS_PLUGIN_DIR.";
      exit $rc;
    fi
  fi

  if [ ! -d "$OS_PLUGIN_DIR/default" ]; then
    mkdir -p "$OS_PLUGIN_DIR/default"
    rc=$?;
    if [[ $rc != 0 ]]; then
      echo "Error: Could not create the default plugins directory $OS_PLUGIN_DIR/default. Please ensure you've appropriate rights to create the directory.";
      exit $rc;
    fi
  fi

  if [ ! -d "$OS_PLUGIN_DIR/paid" ]; then
    mkdir -p "$OS_PLUGIN_DIR/paid"
    rc=$?;
    if [[ $rc != 0 ]]; then
      echo "Error: Could not create the paid plugins directory $OS_PLUGIN_DIR/paid. Please ensure you've appropriate rights to create the directory.";
      exit $rc;
    fi
  fi

  if [ ! -d "$OS_PLUGIN_DIR/zustomer" ]; then
    mkdir -p "$OS_PLUGIN_DIR/zustomer"
    rc=$?;
    if [[ $rc != 0 ]]; then
      echo "Error: Could not create the zustomer plugins directory $OS_PLUGIN_DIR/zustomer. Please ensure you've appropriate rights to create the directory.";
      exit $rc;
    fi
  fi

  if [ ! -d "$OS_DATA_DIR" ];then
    mkdir -p $OS_DATA_DIR
    rc=$?;
    if [[ $rc != 0 ]]; then
      echo "Error: Could not create the data directory $OS_DATA_DIR. Please ensure you've appropriate rights to create the directory.";
      exit $rc;
    fi
  fi
}

checkAndCreatePluginsCSV() {
plugin_csv="$OS_DATA_DIR/plugin.csv"
# Check if plugin.csv file is present
if [ -f "$plugin_csv" ]; then
    rm -v $plugin_csv
    # Loop through paid and zustomer directories
    for dir_name in "paid" "zustomer"; do
        # Check if the directory exists and has files
        if [ -d "$OS_PLUGIN_DIR/$dir_name" ] && [ "$(ls -A "$OS_PLUGIN_DIR/$dir_name")" ]; then
            # Loop through files in the directory
            for file_path in "$OS_PLUGIN_DIR/$dir_name/"*; do
                if [ -f "$file_path" ]; then
                    folder_name="$dir_name"
                    file_name=$(basename "$file_path" | cut -d',' -f2-3 | cut -d'-' -f1-2)
                    echo "$folder_name,$file_name" >> "$plugin_csv"
                fi
            done
        fi
    done

    if [ -f "$plugin_csv" ]; then
        echo "Created $plugin_csv"
    else
        echo "No plugins are present in paid and zustomer."
    fi
fi
}

compPaidPlug() {

# Get the list of plugins from the plugin.csv file
p_name=$(cat $OS_DATA_DIR/plugin.csv | cut -d',' -f2-3 | cut -d'-' -f1-2)

# Get the list of plugins in the new_plugins directory
n_name=$(ls new_plugins/ | cut -d'-' -f1-2)

# Compare the two lists of plugins
if [ "$p_name" != "$n_name" ]; then
  # Not matching, abort the script and prompt the user to download the missing plugins
  missing_plugins=$(comm -3 <(echo "$p_name" | sort) <(echo "$n_name" | sort) | tr '\n' ' ')
  echo "Plugins are not matched. Please download the following missing plugins: $missing_plugins and try to run again."
  exit 1
else
  echo "All plugins present"
fi

}

backupOldBuild() {
  echo "Creating backup directory $OS_DATA_DIR/old_builds/$BACKUP_DIR";
  mkdir -p $OS_DATA_DIR/old_builds/$BACKUP_DIR/plugins/{defaults,paid,zustomer}
  mkdir -p $OS_DATA_DIR/old_builds/$BACKUP_DIR/db-connectors
  rc=$?;
  if [[ $rc != 0 ]]; then
    echo "Error: Could not create the builds backup directory $OS_DATA_DIR/old_builds/$BACKUP_DIR. Please ensure you've appropriate rights to create the directory.";
    exit $rc;
  fi

  echo "Shutting down the Tomcat server ...";
  $TOMCAT_PATH/bin/./shutdown.sh -force

  echo "Waiting for the Tomcat server to shutdown ..."
  sleep 5
  
  rc=$(ls $OS_PLUGIN_DIR/default/*.jar | wc -l)
  if [[ $rc == 0 ]]; then
    echo "Plugins of older version not found.";
  else
    echo "Taking backup of the $OS_PLUGIN_DIR/default folder ...";
    mv $OS_PLUGIN_DIR/default/*.jar $OS_DATA_DIR/old_builds/$BACKUP_DIR/plugins/defaults
    mv $OS_PLUGIN_DIR/paid/*.jar $OS_DATA_DIR/old_builds/$BACKUP_DIR/plugins/paid/
    cp $OS_PLUGIN_DIR/zustomer/*.jar $OS_DATA_DIR/old_builds/$BACKUP_DIR/plugins/zustomer/
  fi

  #This code take backup of plugins present in orignal plugin_dir directory.
  #From OpenSpecimen v7.1 onwards, Enterprise Edition plugins are stored in $OS_PLUGIN_DIR/default/ directory.
  rc=$(ls $OS_PLUGIN_DIR/*.jar | wc -l)
  if [[ $rc != 0 ]]; then
    mkdir -p $OS_DATA_DIR/old_builds/$BACKUP_DIR/temp_plugins
    mv $OS_PLUGIN_DIR/*.jar $OS_DATA_DIR/old_builds/$BACKUP_DIR/temp_plugins
  fi

  rc=$(ls $TOMCAT_PATH/webapps/$WAR_NAME.war | wc -l)
  if [[ $rc == 0 ]]; then
    echo "WAR of older version not found.";
  else
    echo "Taking backup of WAR file ...";
    rm -rf $TOMCAT_HOME/webapps/$WAR_NAME
    mv $TOMCAT_PATH/webapps/$WAR_NAME $OS_DATA_DIR/old_builds/$BACKUP_DIR/
  fi

  echo "Taking backup of the connector jars ...";
  mv $TOMCAT_PATH/lib/mysql-connector*.jar $OS_DATA_DIR/old_builds/$BACKUP_DIR/db-connectors/
  mv $TOMCAT_PATH/lib/ojdbc*.jar $OS_DATA_DIR/old_builds/$BACKUP_DIR/db-connectors/
}

deployMatchPlug() {
    declare -A created_dirs  # Associative array to track created directories

    # Read the CSV file line by line
    while IFS=',' read -r folder_name file_name; do
        # List files in the new_plugins directory based on the file_name pattern
        matched_files=(new_plugins/"$file_name"*)
        # Loop through matched files and copy them to the destination directory
        for matched_file in "${matched_files[@]}"; do
            if [ -f "$matched_file" ]; then
                destination="$OS_PLUGIN_DIR/$folder_name/" 
                cp "$matched_file" "$destination"
                echo "Copied $matched_file to $destination"
            fi
        done
    done < "$OS_DATA_DIR/plugin.csv"
}

deployNewBuild() {
  echo "Web App name : $WAR_NAME";
  
  echo "Copying $PROPERTY_FILE to $TOMCAT_PATH/conf/$WAR_NAME.properties"
  cp $PROPERTY_FILE $TOMCAT_PATH/conf/$WAR_NAME.properties

  echo "Copying database connector jars to $TOMCAT_PATH/lib"
  cp db-connectors/mysql-connector*.jar $TOMCAT_PATH/lib/ 
  cp db-connectors/ojdbc*.jar $TOMCAT_PATH/lib/

  echo "Copying new plugins ...";
  cp plugin_build/*.jar $OS_PLUGIN_DIR/default
  #cp new_plugins/*.jar $OS_PLUGIN_DIR/paid


  echo "Copying new WAR ...";
  cp openspecimen.war $TOMCAT_PATH/webapps/$WAR_NAME.war

  echo "Starting Tomcat server ...";
  $TOMCAT_PATH/bin/./startup.sh

  echo "#####################################################################"
  echo "OpenSpecimen is installed successfully.Please check the log files."
  echo "You can find log files at following locations: "
  echo "Tomcat logs: $TOMCAT_PATH/logs/catalina.out"
  echo "OpenSpecimen logs: $OS_DATA_DIR/logs/os.log"
  echo "#####################################################################"
}

main() {
  ensurePropsFileSpecified;
  initVariables;
  ensurePrerequisites;
  ensureDataAndPluginDirsExist;
  checkAndCreatePluginsCSV;
  compPaidPlug;
  backupOldBuild;
  deployMatchPlug
  deployNewBuild;
}

main;