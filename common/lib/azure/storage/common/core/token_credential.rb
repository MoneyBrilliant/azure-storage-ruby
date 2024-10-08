# frozen_string_literal: true

#-------------------------------------------------------------------------
# # Copyright (c) Microsoft and contributors. All rights reserved.
#
# The MIT License(MIT)

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files(the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions :

# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#--------------------------------------------------------------------------
require "azure/core"

module Azure::Storage::Common::Core
  class TokenCredential
    # Public: Initializes an instance of [Azure::Storage::Common::Core::TokenCredential]
    #
    # ==== Attributes
    #
    # * +token+                           - String. The initial access token.
    #
    def initialize(token)
      @token = token
      @mutex = Mutex.new
    end

    # Public: Gets the access token
    #
    # Note: Providing this getter under the protect of a mutex
    #
    def token
      @mutex.synchronize do
        @token
      end
    end

    # Public: Renews the access token
    #
    # ==== Attributes
    #
    # * +new_token+                       - String. The new access token.
    #
    def renew_token(new_token)
      @mutex.synchronize do
        @token = new_token
      end
    end
  end
end
