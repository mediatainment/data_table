module DataTable

  def self.included base
    base.send :extend, ClassMethods
    base.send :extend, Mongoid::ClassMethods
  end

  module ClassMethods
    def for_data_table controller, fields, search_fields=nil, explicit_block=nil, &implicit_block
      params = controller.params
      search_fields ||= fields
      block = (explicit_block or implicit_block)

      objects = _find_objects params, fields, search_fields

      {:sEcho                => params[:sEcho].to_i,
       :iTotalRecords        => self.count,
       :iTotalDisplayRecords => objects.total_entries,
       :aaData               => _yield_and_render_array(controller, objects, block)
      }.to_json.html_safe
    end

    private

    def _yield_and_render_array controller, objects, block
      objects.map do |object|
        block[object].map do |string|
          controller.instance_eval %{
            Rails.logger.silence do
              render_to_string :inline => %Q|#{string}|, :locals => {:#{self.name.underscore} => object}
            end
          }
        end
      end
    end

    def _page params
      params[:iDisplayStart].to_i / params[:iDisplayLength].to_i + 1
    end
  end

end
