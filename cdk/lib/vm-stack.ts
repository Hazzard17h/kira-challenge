import { CfnOutput, Stack, StackProps } from 'aws-cdk-lib';
import { CfnKeyPair, Instance, InstanceType, MachineImage, Peer, Port, SecurityGroup, SubnetType, Vpc } from 'aws-cdk-lib/aws-ec2';
import { Construct } from 'constructs';

export interface VMStackProps extends StackProps {
  readonly sshPublicKey: string;

  readonly masterInstanceType?: string;

  readonly workersInstanceType?: string;
}

export class VMStack extends Stack {
  constructor(scope: Construct, id: string, props: VMStackProps) {
    super(scope, id, props);

    const defaultInstanceType = 't3.small';

    const { sshPublicKey, masterInstanceType = defaultInstanceType, workersInstanceType = defaultInstanceType } = props;

    const vpc = new Vpc(this, 'Vpc', {
      maxAzs: 1,
      subnetConfiguration: [ {
        name: 'Public',
        subnetType: SubnetType.PUBLIC
      } ]
    });

    const securityGroup = SecurityGroup.fromSecurityGroupId(this, 'SecurityGroup', vpc.vpcDefaultSecurityGroup);
    securityGroup.addIngressRule(Peer.anyIpv4(), Port.tcp(22));
    securityGroup.addIngressRule(Peer.anyIpv4(), Port.tcp(6443));

    const keyName = 'SshKey';
    new CfnKeyPair(this, keyName, { keyName, publicKeyMaterial: sshPublicKey });

    const createInstance = (id: string, type: string) => {
      const instance = new Instance(this, id, {
        vpc,
        instanceType: new InstanceType(type),
        machineImage: MachineImage.fromSsmParameter('/aws/service/canonical/ubuntu/server/focal/stable/current/amd64/hvm/ebs-gp2/ami-id'),
        securityGroup,
        keyName
      });
      new CfnOutput(this, `${id.toLowerCase()}-IP`, { value: instance.instancePublicIp });
      return instance;
    };

    createInstance('Master', masterInstanceType);

    [ 1, 2 ].map(i => createInstance(`Worker-${i}`, workersInstanceType));
  }
}
