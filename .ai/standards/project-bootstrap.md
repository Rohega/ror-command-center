# Project Bootstrap Standard

> Mandatory setup for **new** Ruby on Rails applications created with RoR Command
> Center. The test stack is configured **first**, before application code — this
> removes the chicken-and-egg problem where testing rules only attach once specs
> already exist.

## Test stack is mandatory (RSpec)

A new Rails app is not considered initialized until RSpec is installed and wired.
This is **not optional** and is part of the Definition of Done
(`.cursor/rules/workflow-gates.mdc`).

### 1. Gemfile (`:development, :test`)

```ruby
group :development, :test do
  gem "rspec-rails"
  gem "factory_bot_rails"
end

group :test do
  gem "simplecov", require: false
end
```

### 2. Install RSpec

```bash
bundle install
bundle exec rails generate rspec:install
```

This creates `.rspec`, `spec/spec_helper.rb`, and `spec/rails_helper.rb`.

### 3. Make Rails generators produce specs by default

In `config/application.rb`, so every `rails generate` scaffolds RSpec specs (and no
Minitest, no view/helper/route specs unless needed):

```ruby
config.generators do |g|
  g.test_framework :rspec,
    fixtures: true,
    view_specs: false,
    helper_specs: false,
    routing_specs: false
  g.fixture_replacement :factory_bot, dir: "spec/factories"
end
```

### 4. Coverage (SimpleCov)

At the very top of `spec/spec_helper.rb`:

```ruby
require "simplecov"
SimpleCov.start "rails"
```

### 5. CI runs the suite

The pipeline runs `bundle exec rspec` on every PR to `main` and fails the build on
any failure. See `.ai/standards/testing.md` for coverage expectations and
`.ai/standards/git-workflow.md` for branch protection.

## Bootstrap checklist

- [ ] `rspec-rails` + `factory_bot_rails` in the Gemfile
- [ ] `rspec:install` run (`.rspec`, `spec/rails_helper.rb` present)
- [ ] `config.generators` set to `:rspec` + `:factory_bot`
- [ ] SimpleCov configured
- [ ] CI runs `bundle exec rspec` and fails on red
- [ ] `README.md` present

## References

- Testing principles: `.ai/standards/testing.md`
- Rails conventions: `.ai/standards/development.md`
- Workflow & gates: `.ai/workflows/new-feature.yaml`, `.cursor/rules/workflow-gates.mdc`
