# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: rides
#
#  area_smart           :float
#  area_with_overlap    :float
#  area_without_overlap :float
#  created_at           :datetime         not null
#  creator_id           :integer
#  distance_km          :float
#  duration             :interval
#  equipment_name       :string
#  gasoline             :float
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  nature               :string
#  number               :string
#  product_id           :integer
#  provider             :jsonb
#  ride_set_id          :integer
#  sleep_count          :integer
#  sleep_duration       :interval
#  started_at           :datetime
#  state                :string
#  stopped_at           :datetime
#  updated_at           :datetime         not null
#  updater_id           :integer
#
class Ride < ApplicationRecord
  include Attachable
  include Providable
  include HasInterval
  belongs_to :equipment, class_name: 'Equipment', foreign_key: :product_id
  belongs_to :ride_set
  belongs_to :intervention
  has_many :crumbs, dependent: :destroy
  belongs_to :cultivable_zone

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :area_smart, :area_with_overlap, :area_without_overlap, :distance_km, :gasoline, numericality: true, allow_blank: true
  validates :duration, :equipment_name, :number, :sleep_duration, length: { maximum: 500 }, allow_blank: true
  validates :started_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  validates :stopped_at, timeliness: { on_or_after: ->(ride) { ride.started_at || Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]

  has_interval :duration, :sleep_duration

  # Shape represents a linestring of all crumbs related to the ride
  has_geometry :shape, type: :line_string

  scope :of_nature, ->(nature_name) { where(nature: nature_name) }

  acts_as_numbered :number
  enumerize :nature, in: %i[road work], scope: true
  enumerize :state, in: %i[affected unaffected], default: :unaffected

  state_machine :state do
    state :unaffected
    state :affected

    event :link_intervention do
      transition unaffected: :affected
    end
  end

  after_update do
    self.link_intervention if self.intervention_id.present?
  end

  def working_zone
    width = begin
              equipment.width
            rescue NoMethodError => e
              3.5
            end
    line = ::Charta.make_line(crumbs.order(:read_at).pluck(:geolocation))
    line.to_rgeo.buffer( width / 2)
  end

  %i[duration sleep_duration].each do |col|
    define_method "decorated_#{col}" do
      decorate.send(col)
    end
  end
end
