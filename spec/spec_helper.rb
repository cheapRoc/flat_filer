require 'pathname'
require Pathname(__FILE__).dirname.parent.join('lib', 'flat_file')
require 'spec'

class FlatClass < FlatFile; end

class PersonFile < FlatFile

  EXAMPLE_FILE = <<-EOF
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF

  add_field :f_name, :width => 10

  add_field :l_name, :width => 10, :aggressive => true

  add_field :phone, :width => 10,
    :map_in_proc => proc { |model, record|
      return if model.phone
      model.phone = record.phone
    }

  add_field :age, :width => 4,
    :filter => proc { |v| v.to_i },
    :formatter => proc { |v| v.to_f.to_s }

  pad :auto_name, :width => 3

  add_field :ignore, :width => 3, :padding => true

end

class PersonAddressFile < FlatFile

  EXAMPLE_FILE = <<-EOF
1234567890123456789012345678901234567890
People Recs CHEM-101   010109        xxx
1234567890123456789012345678901234567890
f_name    l_name              age pad---
Captain   Stubing             4      xxx
No        Phone               5      xxx
Has       Phone     11111111116      xxx

EOF
  
  layout :header, :rows => 1 do

    add_field :title, :width => 12

    add_field :department, :width => 10

    add_field :created_at, :width => 6

    pad :auto_name, :width => 5

    add_field :ignore, :width => 5, :padding => true

  end

  layout :person do

    add_field :f_name, :width => 10

    add_field :l_name, :width => 10, :aggressive => true

    add_field :phone, :width => 10,
      :map_in_proc => proc { |model, record|
        return if model.phone
        model.phone = record.phone
      }

    add_field :age, :width => 4,
      :filter => proc { |v| v.to_i },
      :formatter => proc { |v| v.to_f.to_s }

    pad :auto_name, :width => 3

    add_field :ignore, :width => 3, :padding => true

  end

end
