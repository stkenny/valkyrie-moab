# Valkyrie::Moab

A [Moab](http://journal.code4lib.org/articles/8482) storage backend for [Valkyrie](https://github.com/samvera-labs/valkyrie)

## Requirements

### Ruby version
Ruby 2.3 or above

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'valkyrie-moab'
```

## Usage

Follow the Valkyrie README to get a development or production environment up and running. 

To enable Moab storage support, add the following to your application's ```config/initializers/valkyrie.rb```:

```ruby
    Valkyrie::StorageAdapter.register(
      Valkyrie::Storage::Moab.new(
          storage_roots: [Rails.root.join("tmp", "moab")], 
          storage_trunk: 'files'
      ),
      :moab
    )
```
You can then use `:moab` as a storage adapter value in `config/valkyrie.yml`

Configure the metadata adapter in Valkyrie by adding the following to your ```config/initializers/valkyrie.rb```:

```ruby
Valkyrie::MetadataAdapter.register(
  Valkyrie::Persistence::Moab::MetadataAdapter.new(
      storage_roots: [Rails.root.join("tmp", "moab")],
      storage_trunk: 'files'
  ),
  :moab
)
```


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/stkenny/valkyrie-moab/.

## License

`Valkyrie::Moab` is available under [the Apache 2.0 license](LICENSE).
