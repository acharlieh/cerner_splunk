Data Bags
=========
Here we'll describe the various types of hashes that come out of [data bag items](http://docs.opscode.com/essentials_data_bags.html) used with `cerner_splunk` cookbook, and their formats.

It is recommended that all of these items live in an `cerner_splunk` data bag, but they are configurable through [attributes](attributes.md) and keys on other Hashes.

Hashes and other values stored in data bag items are referenced by strings that take the form "data_bag/data_bag_item:key" which would reference the key, inside a particular data_bag_item inside a particular data bag. Similarily, An entire data bag item could be referenced by a string matching "data_bag/data_bag_item"

Contextual Hashes
-----------------
If a hash is marked as being contextual, after resolving the overall hash by the coordinate given, we then attempt to resolve a hash out of that hash, by looking for keys matching (in order) the splunk node name e.g. `node[:splunk][:config][:host]`, the Chef node name, the node fully qualified domain name, the splunk node type, and the empty string. Each of these context keys can be missing (in which case resolution will attempt the next one in the list, or return nil if no more contexts exist to try), or can terminate with a hash, a String aliasing that particular context to another context, or null (meaning explicitly unconfigured). The code behind this is in the recipe.rb library in CernerSplunk.keys (to get the context resolution order) and in the databags.rb library, CernerSplunk::DataBag.load with the pick_context option to perform the resolution.

Cluster Hash
------------
The Cluster Hash is part of a plaintext data bag item that defines a logical group of Splunk Servers (Often a single master and multiple slave VMs). It is created and owned by the splunk cluster administrator, and is referenced by others who want to point forwarders or search heads to the cluster.

* `['license_uri']` - SplunkAPI URI of the License Server (Required for getting onto the Enterprise license, if unset, use trial license)
* `['master_uri']` - SplunkAPI URI of the cluster master (Required for servers connecting to managed clusters)
* `['deployer_uri']` - SplunkAPI URI of the Deployer in the Search Head Cluster
* `['shc_members']` - Array of Splunk API URIs of the search head members that are in the SH (Search Head) cluster. Always make sure that the first SH member in the array is an existing member in the cluster.
* `['settings']` -  Hash of Cluster settings (Required for servers connecting to managed clusters),
* `['settings'][???]` - Valid values are those under the clustering stanza of [server.conf][]
* `['settings'][???]['_cerner_splunk_indexer_count']` - The number of indexers to use for calculating maxTotalDataSizeMB for each index in combination with _maxDailyDataSizeMB in the index configuration.
* `['shc_settings'] - Hash of SH Cluster settings
* `['shc_settings']['???']` - Valid values are those under the shclustering stanza of [server.conf][]
* `['replication_ports']` - Configuration for cluster slave replication ports (required for cluster slaves)
* `['replication_ports']['###']` - Port number to listen on
* `['replication_ports']['###']['_cerner_splunk_ssl']` - boolean if the port is ssl enabled (false)
* `['replication_ports']['###']['???']` - Other replication-port stanza properties from [server.conf][]
* `['receivers']` - Array of strings of hosts where this cluster's indexers are listening. (Required for forwarders)
* `['receiver_settings']['splunktcp']['port']` - Port indexers are listening on, and forwarders are sending data (required for forwarders and receivers)
* `['indexes']` - A String pointing to an indexes data bag hash. (Coordinate form as described above)
* `['apps']` - A String pointing to an apps data bag hash. (Coordinate form as described above)

License Hash
------------
The License Hash is part of a data bag item encrypted with [Chef Vault](https://github.com/Nordstrom/chef-vault) to hold the license data.

* `[A Decriptive File-Name]` - Corresponding License (XML) contents. (There can be many of these) Remember to change newlines to `\n` to conform to proper JSON format.

License Pool Hash
------------
This hash is part of a plaintext data bag item that defines multiple license pools. Indexers can be assigned to a specific pool and license quota can be set for each pool by configuring this databag. Quota can be specified in units of B, KB(or KiB), MB(MiB), GB(GiB) or TB(TiB)(e.g. '400MB' or '400GiB'). If the unit is not specified then the quota is assumed to be in bytes.

* `['auto_generated_pool_size']` - This is the pool size for the auto generated pool. Indexers that connect to the license server, when not assigned to a specific pool will land in this pool.
* `['pools'][pool_name]['size']` -  Size of the pool
* `['pools'][pool_name]['GUIDs']` - List of Indexer GUIDs that needs to be assigned to this pool.

Indexes Hash
------------
An Indexes Hash is part of a plaintext data bag item that defines the set of indexes defined in a cluster. It is separate from the Cluster data bag primarily for size concerns.

* `['config']` - These define the [indexes.conf] stanzas (in fairly raw form). However there are a few special keys:
    * `_volume` - The base volume for the coldPath, homePath and tstatsHomePath. Defaults to nil, so the index will be located in $SPLUNK_DB.
    * `_directory_name` - The on-disk name of the directory to store the index. Defaults to the index name.
    * `_maxDailyDataSizeMB` - The amount of daily usage this index is expected to consume.  Used to calculate the maxTotalDataSizeMB if maxTotalDataSizeMB has not already been specified for the index.
    * `_dataSizePaddingPercent` - The percentage of padding to apply to the amount of space this index is expected to consume.  Used to calculate the maxTotalDataSizeMB if maxTotalDataSizeMB has not already been specified for the index. Defaults to 10 if no value is specified.
* `['flags']` - These define boolean processing flags per index. All flags are default 'false' but can be set to true. Current flags include:
    * `noGeneratePaths` - Do not generate the homePath,coldPath,thawedPath to this index when not present in the config above
    * `noRepFactor` - Do not add 'repFactor = auto' to this index when not present in the config on a cluster master.
* `['metadata']` - These define ownership / other reference metadata around indexes and their owners (ALPHA!!! CAN CHANGE!!!)

Roles Hash
----------
A Roles Hash is a contextual (see above) Hash, part of a plaintext data bag item that defines roles for every node in a cluster, and is pointed to by the `node[:splunk][:config][:roles]` attribute (usually set in your environment). A special key of 'shc_configs' is used for managing the roles on the search heads in a search head cluster.

* `[context]` - Final Hash, String Alias, or force unconfigured (null)
* `[context]['default']` - defines the base settings for all roles
* `[context][role_name]` - defines the settings for a particular role
* `[context][role_name]['app']` - Default app for the role ('default_namespace' in [user-prefs.conf][])
* `[context][role_name]['tz']` - Default timezone for the role ('tz' in [user-prefs.conf][])
* `[context][role_name]['showWhatsNew']` - 0 to supress the "what's new in Splunk 6 popup" ('showWhatsNew in [user-prefs.conf][])
* `[context][role_name]['capabilities']` - An array of capability names to enable for this role or when prefixed with an '!' to explicitly disable (which is only useful when applied to those roles that ship with Splunk/other apps in default configurations) in [authorize.conf][].
* `[context][role_name][something_else]` - A string, or array for something else defined in [authorize.conf][]. Arrays are automatically turned into semi-colon delimited lists.

Authentication Hash
-------------------
An Authentication Hash is a contextual (see above) Hash, part of a plaintext data bag item that is used to configure how users authenticate to the system per [authentication.conf][].
A special key of 'shc_configs' is used for managing the authentication on the search heads in a search head cluster.

* `['authType']` - Matches the key of the same name in the authentication stanza. One of Splunk, LDAP, Scripted, but we'll attempt to guess it based on the other configured keys
* `['passwordHashAlgorithm']` - Only valid for 'Splunk' authType. See key of the same name in the authentication stanza
* `['scriptPath']` - Only valid for the 'Scripted' authType, see key in the authSettings
* `['scriptSearchFilters']` - Only valid for the 'Scripted' authType, see key of the same name in authentication settings.
* `['cacheTiming']` - Only valid for the 'Scripted' authType, Hash configuring stanza of the same name.
* `['LDAP_strategies']` - An LDAP Hash, A string pointing to an LDAP Hash, or an Array of Strings and Hashes.
* `['LDAP_strategies']['bag']` - If an LDAP_Strategies item is a hash, this points to the LDAP Hash of defaults, that can have portions overriden by the rest of the local hash.

LDAP Hash
---------
An LDAP Hash is part of a plaintext data bag item that configures connection information to LDAP. It can be referenced from or defined as part of 'LDAP_strategies'

* `['strategy_name']` - What to call the strategy. By default this is derived from a combination of the host/port.
* `['roleMap']` - Hash mapping Splunk roles to 1 to many LDAP roles
* `['roleMap'][splunk_role]` - String or Array of Strings of LDAP roles to map the given splunk role to
* `['bindDNpassword']` - Coordinate String (see above), pointing to a String within a Chef Vault encrypted data bag item.
* `[other]` - Other keys under an LDAP <authSettings-key> stanza as documented in [authentication.conf][].

Alerts Hash
-----------
An Alerts hash is a contextual (see above) Hash, part of a plaintext data bag item that configures [alert-actions.conf][]. A special key of 'shc_configs' is used for managing the alerts on the search heads in a search head cluster.

* `['bag']` - A string that points to an externalized Alerts Hash in which all keys (except this one) are valid
* `['email']['auth_password']` - Coordinate String (see above), pointing to a String within a Chef Vault encrypted data bag item.
* `[stanza][key]` - Any other stanza/key combination from [alert-actions.conf][]

Apps Hash
-----------
An apps hash is a contextual (see above) Hash, part of a plaintext data bag item or specified directly as attributes that configures apps. A special key of 'master-apps' is looked for managing apps that should be installed and pushed by the cluster master, instead of locally. On a deployer in a Search Head Cluster, the key 'deployer-apps' is used for managing the apps that should be installed on the deployer and then pushed to the search heads.

* `['bag']` - A string that points to an externalized Apps Hash in which all keys (except this one) are valid.
* `[app]` - The name of an app to manage (disk name)
* `[app]['remove']` - If true, remove this app instead of creating / managing  (default - false)
* `[app]['local']` - If true, manage `[app]['files']` defined files and `[app]['permissions']` defined metadata in the "local" directory and "local.meta" instead of the "default" directory and "default.meta" (default - false, but forced true if download-url is specified)
* `[app]['download']` - Information for downloading an app
* `[app]['download']['url']` - URL of where to download the app .tar.gz or .spl file. Archive is expected to contain a top-level directory with name matching 'app' attribute above.
* `[app]['download']['version']` - Expected [version number][app.conf] (if any) used to determine if a new app should be downloaded.
* `[app]['files']` - Hash of files to manage under the "default" or "local" directory.
* `[app]['files'][filename]` - Contents of a particular file to manage. It can take 3 values, a hash of stanzas -> key-value pairs (then written with the splunk template), a string (written as is), or nil / false (deleted). If the hash or string is empty, the file is also deleted.
* `[app]['lookups']` - Hash of lookup files for the app. The key in the hash will be the name of file when it lands in the Splunk app and the value will be the url to lookup file. To delete an existing lookup file, set the value of the lookup file to `false` or `null` or to an empty string. The only supported file name extensions are .csv, .csv.gz and .kmz. Please see [splunk docs](http://docs.splunk.com/Documentation/Splunk/6.3.2/Knowledge/Addfieldsfromexternaldatasources) for more information about the supported file formats. `[app]['files']` hash can be used to specify any .conf setting that is required for the lookup.
* `[app]['permissions']` - Hash of permissions to manage for the app.
* `[app]['permissions'][object]` - Permissions to manage for a particular knowledge object or class of knowledge objects
* `[app]['permissions'][object]['access']['read']` - array of roles or String '*' allowed to read the object
* `[app]['permissions'][object]['access']['write']` - array of roles or String '*' allowed to write the object
* `[app]['permissions'][object][???]` - Any other stanza from [default.meta][]

UI Hash
-----------
An UI hash is a contextual (see above) Hash, part of a plaintext data bag item that configures [ui-prefs.conf][]. A special key of 'shc_configs' is used for managing the alerts on the search heads in a search head cluster.

* `['bag']` - A string that points to an externalized Alerts Hash in which all keys (except this one) are valid
* `[stanza][key]` - Any other stanza/key combination from [ui-prefs.conf][]


Docs Navigation
===============
* [Docs Readme](README.md)
* [Repository Readme](../README.md)

[server.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Serverconf
[indexes.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Indexesconf
[user-prefs.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/User-prefsconf
[authorize.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Authorizeconf
[authentication.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Authenticationconf
[alert-actions.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Alert-actionsconf
[default.meta]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Defaultmetaconf
[app.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/appconf
[ui-prefs.conf]: http://docs.splunk.com/Documentation/Splunk/latest/Admin/Ui-prefsconf