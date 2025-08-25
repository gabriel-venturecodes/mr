class EnablePgvectorExtension < ActiveRecord::Migration[8.0]
  def change
    # Skip pgvector for now - can be enabled later when extension is available
    # enable_extension 'vector'
  end
end
