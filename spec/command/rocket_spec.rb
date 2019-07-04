require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Rocket do

    begin
      Pod::Command.run(%w{ rocket init})
    rescue

    end
  end
end


