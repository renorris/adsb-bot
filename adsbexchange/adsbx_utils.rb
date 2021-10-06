require 'sqlite3'

module ADSBx
  module Utils
    def self.hex_for_n_number(n_number)
      db = SQLite3::Database.new './adsbexchange/planes.db'
      rows = db.execute('select * from planes where nnum=?', n_number)
      if rows.empty?
        [false, 'Unknown n-number']
      else
        [true, rows[0][1]]
      end
    end
  end
end


