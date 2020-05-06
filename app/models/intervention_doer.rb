# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: intervention_parameters
#
#  allowed_entry_factor     :interval
#  allowed_harvest_factor   :interval
#  applications_frequency   :interval
#  assembly_id              :integer
#  batch_number             :string
#  component_id             :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  currency                 :string
#  dead                     :boolean          default(FALSE), not null
#  event_participation_id   :integer
#  group_id                 :integer
#  id                       :integer          not null, primary key
#  identification_number    :string
#  imputation_ratio         :decimal(19, 4)
#  intervention_id          :integer          not null
#  lock_version             :integer          default(0), not null
#  new_container_id         :integer
#  new_group_id             :integer
#  new_name                 :string
#  new_variant_id           :integer
#  outcoming_product_id     :integer
#  position                 :integer          not null
#  product_id               :integer
#  quantity_handler         :string
#  quantity_indicator_name  :string
#  quantity_population      :decimal(19, 4)
#  quantity_unit_name       :string
#  quantity_value           :decimal(19, 4)
#  reference_data           :jsonb            default("{}")
#  reference_name           :string           not null
#  type                     :string
#  unit_pretax_stock_amount :decimal(19, 4)   default(0.0), not null
#  updated_at               :datetime         not null
#  updater_id               :integer
#  usage_id                 :string
#  using_live_data          :boolean          default(TRUE)
#  variant_id               :integer
#  variety                  :string
#  working_zone             :geometry({:srid=>4326, :type=>"multi_polygon"})
#
class InterventionDoer < InterventionAgent
  belongs_to :event_participation, dependent: :destroy
  belongs_to :intervention, inverse_of: :doers

  before_save do
    if product && product.respond_to?(:person) && product.person
      columns = { event_id: event.id, participant_id: product.person_id, state: :accepted }
      if event_participation
        # self.event_participation.update_columns(columns)
        event_participation.attributes = columns
      else
        event_participation = EventParticipation.create!(columns)
        # self.update_column(:event_participation_id, event_participation.id)
        self.event_participation_id = event_participation.id
      end
    elsif event_participation
      event_participation.destroy!
    end
  end

  scope :with_empty_participations, lambda {
    InterventionDoer
      .select do |intervention_doer|
        next if intervention_doer.intervention.nil?

        intervention_doer.intervention.participations.where(product_id: intervention_doer.product_id).empty?
      end
  }

  def working_duration_params
    { intervention: intervention,
      participation: participation,
      product: product }
  end
end
