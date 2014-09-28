require 'miasma'

module Miasma
  module Models
    autoload :AutoScale, 'miasma/models/auto_scale'
    autoload :BlockStorage, 'miasma/models/block_storage'
    autoload :Compute, 'miasma/models/compute'
    autoload :Dns, 'miasma/models/dns'
    autoload :LoadBalancer, 'miasma/models/load_balancer'
    autoload :Orchestration, 'miasma/models/orchestration'
    autoload :Queues, 'miasma/models/queues'
    autoload :Storage, 'miasma/models/storage'
  end
end
