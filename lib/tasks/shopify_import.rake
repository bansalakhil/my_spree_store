namespace :shopify do
  desc "Import customers from Shopify"
  task :import_customers => :environment do
    puts Shopify.url("customers")
  end
end