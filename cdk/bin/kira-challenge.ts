#!/usr/bin/env node

import 'source-map-support/register';
import { App, Aspects, CfnResource, RemovalPolicy } from 'aws-cdk-lib';
import { readFileSync } from 'fs';
import { homedir } from 'os';

import { VMStack } from '../lib/vm-stack';

const app = new App();

new VMStack(app, 'VMStack', {
  sshPublicKey: readFileSync(process.env.SSH_PUBLIC_KEY_FILE ?? `${homedir()}/.ssh/id_rsa.pub`, { encoding: 'utf8' }),
  masterInstanceType: process.env.CDK_MASTER_INSTANCE,
  workersInstanceType: process.env.CDK_WORKERS_INSTANCE
});

Aspects.of(app).add({ visit: node => node instanceof CfnResource && node.applyRemovalPolicy(RemovalPolicy.DESTROY) });
