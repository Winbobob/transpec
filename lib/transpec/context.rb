# coding: utf-8

require 'transpec/util'

module Transpec
  class Context
    include Util

    SCOPE_TYPES = [:module, :class, :sclass, :def, :defs, :block].freeze

    EXAMPLE_GROUP_METHODS = [
      :describe, :context,
      :shared_examples, :shared_context, :share_examples_for, :shared_examples_for
    ].freeze

    EXAMPLE_METHODS = [
      :example, :it, :specify,
      :focus, :focused, :fit,
      :pending, :xexample, :xit, :xspecify
    ].freeze

    HOOK_METHODS = [:before, :after, :around].freeze

    HELPER_METHODS = [:subject, :subject!, :let, :let!]

    attr_reader :nodes

    # @param nodes [Array] An array containing from root node to the target node.
    def initialize(nodes)
      @nodes = nodes
    end

    def scopes
      @scopes ||= begin
        scopes = @nodes.map { |node| scope_type(node) }
        scopes.compact!
        scopes.extend(ArrayExtension)
      end
    end

    def in_example_group?
      return @in_example_group if instance_variable_defined?(:@in_example_group)

      @in_example_group = scopes == [:def] ||
                          scopes.end_with?(:example_group, :example) ||
                          scopes.end_with?(:example_group, :hook) ||
                          scopes.end_with?(:example_group, :helper) ||
                          scopes.end_with?(:example_group, :def) ||
                          scopes.end_with?(:rspec_configure, :hook) ||
                          scopes.end_with?(:rspec_configure, :def) ||
                          scopes.end_with?(:module, :def)
    end

    def non_monkey_patch_expectation_available?
      in_example_group?
    end

    alias_method :expect_to_matcher_available?, :non_monkey_patch_expectation_available?

    private

    def scope_type(node)
      return nil unless SCOPE_TYPES.include?(node.type)

      if node.type == :block
        special_block_type(node)
      else
        node.type
      end
    end

    def special_block_type(block_node)
      send_node = block_node.children.first
      receiver_node, method_name, *_ = *send_node

      if const_name(receiver_node) == 'RSpec' && method_name == :configure
        :rspec_configure
      elsif HOOK_METHODS.include?(method_name)
        :hook
      elsif receiver_node
        nil
      elsif EXAMPLE_GROUP_METHODS.include?(method_name)
        :example_group
      elsif EXAMPLE_METHODS.include?(method_name)
        :example
      elsif HELPER_METHODS.include?(method_name)
        :helper
      else
        nil
      end
    end

    module ArrayExtension
      def end_with?(*args)
        tail = args.flatten
        self[-(tail.size)..-1] == tail
      end
    end
  end
end
