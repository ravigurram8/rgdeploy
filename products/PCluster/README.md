# Pipelines for RLCatalyst Research Gateway based on Nextflow

Use the below command to start the packer script after providing necessary details in [configuration.json](machine-images/config/infra/configuration.json)

> cd products/Nextflow-Advanced/machine-images/config/infra

> sudo packer build -var-file=configuration.json packer-ec2-nextflow-workspace.json