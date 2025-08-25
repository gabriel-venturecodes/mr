# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create demo user for authentication
unless User.exists?(email: 'demo@mr.ai')
  User.create!(
    email: 'demo@mr.ai',
    password: 'password123',
    password_confirmation: 'password123'
  )
  puts "Created demo user: demo@mr.ai (password: password123)"
end

# Load the golden dataset seeder
require_relative 'seeds/golden_dataset_seeder'

# Seed the golden dataset for demo
GoldenDatasetSeeder.seed!
