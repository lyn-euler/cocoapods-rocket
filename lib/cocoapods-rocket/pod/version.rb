module Pod
  class Version

    def rocket_patch_bump
      @bump ||= begin
        segments = self.segments
        segments.pop while segments.any? { |s| String === s }
        segments.pop if segments.size > 3

        segments[2] = segments[2].succ
        self.class.new segments.join(".")
      end
    end
  end
end
