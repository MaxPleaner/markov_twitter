
###############################################################################
#                              
#                      /\/\   __ _ _ __| | _______   __                   
#                     /    \ / _` | '__| |/ / _ \ \ / /                   
#                    / /\/\ \ (_| | |  |   < (_) \ V /                    
#                    \/    \/\__,_|_|  |_|\_\___/ \_/                     
#                     _____           _ _   _                             
#                    /__   \__      _(_) |_| |_ ___ _ __                  
#                      / /\/\ \ /\ / / | __| __/ _ \ '__                  
#                     / /    \ V  V /| | |_| ||  __/ |                    
#                     \/      \_/\_/ |_|\__|\__\___|_|                    
#                      
###############################################################################

# =============================================================================
# Dependencies
# =============================================================================

# Using a gem to interact with twitter saves a lot of work
require 'twitter'

# Extensions to Ruby core language
require 'active_support/all'

# =============================================================================
# Top level namespace
# =============================================================================

class MarkovTwitter; end

# =============================================================================
# Individual components
# =============================================================================

require "markov_twitter/tweet_reader"
require "markov_twitter/authenticator"
require "markov_twitter/markov_builder"
require "markov_twitter/markov_builder/node"

require "markov_twitter/test_helper_methods"