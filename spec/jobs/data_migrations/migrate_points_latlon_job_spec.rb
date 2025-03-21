# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DataMigrations::MigratePointsLatlonJob, type: :job do
  describe '#perform' do
    it 'updates the lonlat column for all tracked points' do
      user = create(:user)
      point = create(:point, latitude: 2.0, longitude: 1.0, user: user)

      expect { subject.perform(user.id) }.to change {
        point.reload.lonlat
      }.to(RGeo::Geographic.spherical_factory.point(1.0, 2.0))
    end
  end
end
