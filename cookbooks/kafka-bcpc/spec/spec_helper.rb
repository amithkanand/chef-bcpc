require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do | config |
  config.cookbook_path = "../../"
  config.log_level = :debug
  config.role_path = "../../../roles"
  config.platform = "ubuntu"
end
