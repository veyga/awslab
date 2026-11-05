// the use of bottlerocket means each karpenter node gets 2 ebs volumes
resource "kubernetes_manifest" "karpenter_nodeclass" {
  manifest = yamldecode(<<-EOF
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: ${var.node_class_name}
spec:
  amiSelectorTerms:
    - alias: ${var.ami}@latest
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: ${var.root_volume_gb}Gi
        volumeType: gp3
        deleteOnTermination: true
        tags:
          Name: "${var.cluster_name}-${var.node_class_name}-root"
  role: "karpenter-${var.cluster_name}"
  securityGroupSelectorTerms:
    - id: ${var.security_group_id}
  subnetSelectorTerms:
%{for subnet in var.subnets~}
    - id: ${subnet.id}
%{endfor~}
  tags:
    karpenter.sh/discovery: ${var.cluster_name}
%{for key, value in var.tags~}
    ${key}: ${value}
%{endfor~}
    EOF
  )
}
