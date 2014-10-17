require 'miasma'

module Miasma
  module Utils
    autoload :Lazy, 'miasma/utils/lazy'
    autoload :Memoization, 'miasma/utils/memoization'
    autoload :Immutable, 'miasma/utils/immutable'
  end
end

require 'miasma/utils/animal_strings'
require 'miasma/utils/smash'
