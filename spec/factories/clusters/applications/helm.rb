FactoryBot.define do
  factory :clusters_applications_helm, class: Clusters::Applications::Helm do
    cluster factory: %i(cluster provided_by_gcp)

    trait :not_installable do
      status(-2)
    end

    trait :installable do
      status 0
    end

    trait :scheduled do
      status 1
    end

    trait :installing do
      status 2
    end

    trait :installed do
      status 3
    end

    trait :updating do
      status 4
    end

    trait :updated do
      status 5
    end

    trait :errored do
      status(-1)
      status_reason 'something went wrong'
    end

    trait :update_errored do
      status(6)
      status_reason 'something went wrong'
    end

    trait :timeouted do
      installing
      updated_at { ClusterWaitForAppInstallationWorker::TIMEOUT.ago }
    end

    factory :clusters_applications_ingress, class: Clusters::Applications::Ingress do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end

    factory :clusters_applications_prometheus, class: Clusters::Applications::Prometheus do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end

    factory :clusters_applications_runner, class: Clusters::Applications::Runner do
      cluster factory: %i(cluster with_installed_helm provided_by_gcp)
    end

    factory :clusters_applications_jupyter, class: Clusters::Applications::Jupyter do
      oauth_application factory: :oauth_application
      cluster factory: %i(cluster with_installed_helm provided_by_gcp project)
    end
  end
end
