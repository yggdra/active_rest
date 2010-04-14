Railsspec::Application.routes.draw do |map|

  aresources :companies do
  end

  aresources :users do
  end

  aresources :contacts do
  end

  aresources :companies_transaction do
#, :model => Company
  end

  aresources :companies_read_only do
#, :model => Company
  end
#
#  map.active :basic_features, :model => Company
#  map.active :basic_features_ext_js_upload, :model => Company
#
#  map.active :with_guard_protected_attributes, :model => CompanyProtected
#  map.active :without_guard_protected_attributes, :model => CompanyProtected
#
#  map.active :finder_auto, :model => Company
#  map.active :company_finders, :model => Company
#  map.active :finder_custom, :model => Company
#  map.active :finder_operators, :model => Company
#  map.active :finder_operators_wj, :model => Company
#  map.active :finder_operators_w_join_and_mapping, :model => Company
#  map.active :finder_polymorphic, :model => Contact
#  map.active :index_extra_conditions, :model => Company
#
#  map.active :model_joins_a, :model => Company
#  map.active :model_joins_b, :model => Company
#  map.active :model_joins_c, :model => Company
#  map.active :model_joins_d, :model => Company
#  map.active :model_joins_e, :model => Company
#  map.active :model_joins_f, :model => Company
#
#  map.active :read_only, :model => User
#  map.active :virtual_attributes, :model => UserVirtualAttrs

#  map.connect ':controller/:action/:id'
#  map.connect ':controller/:action/:id.:format'
end
