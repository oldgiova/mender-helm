import ruamel.yaml
import sys
import os
    
yaml_file = sys.argv[1]
update_tag = sys.argv[2]
yaml = ruamel.yaml.YAML()

# load yaml in a safe way
config, ind, bsi = ruamel.yaml.util.load_yaml_guess_indent(open(yaml_file))

# set new tag
config['frontend']['image']['tag'] = str(update_tag)

with open(yaml_file, 'w') as file:
  yaml.dump(config, file)

file.close()
