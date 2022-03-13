<template>
  <div id="app">
    
    <p> ZK IDentity {{this.identity_commit}}</p>
    <p> ETH Address {{this.currentAccount}}</p>
    <button class="primaryButton" @click="connectWallet">Connect Wallet</button>
    <button class="primaryButton" @click="joinGroup">Join Group</button>
    <button class="primaryButton" @click="createProof">Create Proof</button>
    
    <p> Your Semaphore proof {{this.proof}}</p>
    <HelloWorld msg='ayo'/>
  </div>
</template>

<script>
import { ZkIdentity } from "@zk-kit/identity"

// import { Semaphore } from "@zk-kit/protocols"
import HelloWorld from './components/HelloWorld.vue'
import {abi} from './testStake.json'
import { ethers } from "ethers";
import axios from 'axios';



export default {
  name: 'App',
  components: {
    HelloWorld
  },
  mounted() {
    this.checkIfWalletIsConnected();
  },
  data() {
    return {
      currentAccount: null,
      contractAddress:
        "set this to your contract address, if you have more than one contract create more specific variables(greeterAddress or votingAddress)",
      contract:null,
      identity_secret:null,
      identity_commit:null,
      client:null,
      proof:null
    };
  },
 methods: {
  getZKIdentity() {
     const identity = new ZkIdentity()
     const identityCommitment = identity.genIdentityCommitment()
     this.identity_secret=identity
     this.identity_commit=identityCommitment
     return identityCommitment
  },
  connectWallet: async function() {
      try {
        const { ethereum , injected} = window;
        console.log(window)
        if(injected){
          console.log('connecting')
          const client = await injected.connect()          
          this.client=client
          console.log(client)
          const ZKID=await client.getActiveIdentity()
          console.log(await client.getIdentityCommitments())
          console.log(await client.getActiveIdentity())
          this.identity_commit=ZKID;
        }
        if (!ethereum) {
          alert("Get MetaMask!");
          return;
        }
       
       
        const provider = new ethers.providers.Web3Provider(ethereum, "any");
        await provider.send("eth_requestAccounts", []);
        const signer = provider.getSigner();
        
        console.log("Connected",await signer.getAddress());
        const contract= new ethers.Contract('0x465f7Ac3Bd00948fE7Fb8939945dE1bFda62C873',abi,signer)
        
        this.contract=contract
        this.provider=provider;
        this.currentAccount = await signer.getAddress();
      } catch (error) {
        console.log(error);
      }
    },
  joinGroup: async function(){
    let r=await this.contract.addDAOIdentity(
      1,
      ethers.BigNumber.from(`0x${this.identity_commit.toString()}`),
    )
    console.log(await r.wait())
  },
  createProof:async function(){
    const circuitFilePath= "http://localhost:8095/snark/semaphore.wasm"
    const zkeyFilePath= "http://localhost:8095/snark/semaphore_final.zkey"
    let leaves=await this.contract.getGroupCommitments(1)
  
    leaves=leaves.map(element => 
        element._hex.slice(2)
    );
    console.log(leaves)
   
  
    const storageArtifacts = {
                leaves: leaves,
                depth: 20,
                leavesPerNode: 2
            }
        

    try {
      let proof = await this.client.semaphoreProof(
                '1',
                'something',
                circuitFilePath,
                zkeyFilePath,
                storageArtifacts,
            )

         
          proof=JSON.parse(proof)
          console.log("semaphore proof", proof.fullProof);
           const params = {
              proof: proof.solidityProof,
              nullifierHash: proof.fullProof.publicSignals.nullifierHash.toString(),
              entityId: proof.fullProof.publicSignals.externalNullifier,
              challenge: 'something',
            }

            console.log(params)
            const hexified = new (Buffer).from(JSON.stringify(params)).toString(
              'hex',
            )
            this.proof=hexified
            console.log(hexified)
           
      } catch (e) {
           
            console.error(e);
      }
  }
 
}
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
  overflow-wrap: break-word;
}

</style>
