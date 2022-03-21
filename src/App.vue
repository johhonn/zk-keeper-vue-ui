<template>
  <div id="app">
    <h1 style="font-size:100px; margin:0; padding:0">ZK-NFT</h1>
    <h3 style="">Anonymously prove you own an NFT</h3>
    <div class="buttonGroup" style="margin-top: 2em;">
      <button class="big-button" v-if="!this.identity_commit || !this.currentAccount" @click="connectWallet">Connect Wallet</button>


      <b-loading :is-full-page="isFullPage" v-model="isLoading" :can-cancel="true"></b-loading>
      <button class="big-button" v-if="this.identity_commit && !this.joinState && !this.isApproved && (parseInt(this.balance.toString())===0)" @click="mint">Mint NFT</button>
      <button class="big-button" v-if="this.identity_commit && !this.joinState && !this.isApproved && (this.balance>0)" @click="approveNFT">Approve NFT</button>
      <button class="big-button" v-if="this.identity_commit && !this.joinState && this.isApproved && (this.balance>0)" @click="joinGroup">Join Group</button>
      <button class="big-button" v-else-if="this.joinState && !this.proof" @click="createProof">Create Proof</button>
    </div>

    <div class="walletConnect">
      <!-- <p v-if="this.identity_commit" style="" >ZK IDentity {{ this.identity_commit }}</p> -->
      <p v-if="this.currentAccount" style="">🟢 {{ this.currentAccount }}</p>
    </div>

    <div v-if="this.proof">

      <div class="">
        <a id="copyToClipboard" v-on:click.prevent="copyToClipboard" class="button control is-medium">
          <span class="icon">📋</span>
        </a>
      </div>

      <div class="">
        <span v-if="!readMoreActivated" value={this.proof}>{{this.proof.slice(0, 50)}}</span>
        <a class="" v-if="!readMoreActivated" @click="activateReadMore" href=""> expand...</a>
        <span v-if="readMoreActivated" v-html="this.proof"></span>
      </div>

    </div>

    <!-- /* Copied from codepen */ -->
          <div style="min-width:625px;" class="column is-5 is-vertical-centered">
            <div class="field has-addons">
              <button id="copyButton" class="control button is-medium is-primary" v-on:click.prevent="copyToClipboard">Copy 📋</button>

              <!-- <a id="copyToClipboard"  class="button control is-medium ">
                <span class="icon">
                  <i class="fa fa-clipboard"></i> 📋
                </span>
              </a> -->



              <div class="control" style="width:100%">
                <span ref="generator" id="generator" v-if="!readMoreActivated && this.proof" class="input is-medium is-rounded"  type="text" readonly value={this.proof}>{{this.proof.slice(0, 50)}}</span>

                <!-- <input v-on:focus="$event.target.select()" ref="generator" v-model="shownUUID" id="generator" class="input is-medium is-rounded" type="text" readonly placeholder="GUID goes here"> -->
              </div>



            </div>
          </div>


  </div>
</template>

<script>
import { ZkIdentity } from '@zk-kit/identity'
// import { Semaphore } from "@zk-kit/protocols"
import HelloWorld from './components/HelloWorld.vue'
import { abi } from './testStake.json'
import { nft_abi } from './nft.json'
import { ethers } from 'ethers'
import axios from 'axios'
import './assets/my.css';


export default {
  name: 'App',

  data() {
    return {
      currentAccount: null,
      contractAddress:
        'set this to your contract address, if you have more than one contract create more specific variables(greeterAddress or votingAddress)',
      contract: null,
      nft:null,
      identity_secret: null,
      identity_commit: null,
      client: null,

      proof: null,
      joinState: null,
      readMoreActivated: false,
      isLoading: false,
      isFullPage: true,
      balance:0,
      isApproved:false
    }
  },
  methods: {
    copyToClipboard() {
        this.$refs.generator.focus();
        document.execCommand('copy');
        this.$buefy.toast.open('Copied!');
    },
    activateReadMore(){
        this.readMoreActivated = true;
    },
    getZKIdentity() {
      const identity = new ZkIdentity()
      const identityCommitment = identity.genIdentityCommitment()
      this.identity_secret = identity
      this.identity_commit = identityCommitment
      return identityCommitment
    },
    connectWallet: async function () {
      try {
        const { ethereum, injected } = window
        console.log(window)
        if (injected) {
          console.log('connecting....')
          const client = await injected.connect()
          this.client = client
          console.log(`client: ${client}`)
          const ZKID = await client.getActiveIdentity()
          // console.log(await client.getIdentityCommitments())
          // console.log(await client.getActiveIdentity())
          this.identity_commit = ZKID
        }
        if (!ethereum) {
          alert('Get MetaMask!')
          return
        }

        const provider = new ethers.providers.Web3Provider(ethereum, 'any')
        await provider.send('eth_requestAccounts', [])
        const signer = provider.getSigner()

        console.log('Connected: ', await signer.getAddress())
        const contract = new ethers.Contract(
          '0x46857511C4D11b21BCbB5976F7446049af4E7bA3',
          abi,
          signer,
        )
        const nft = new ethers.Contract(
          '0x040F1BcC018cc1e55B8779E723219D24b71e7c45',
          nft_abi,
          signer,
        )
       
        this.contract = contract
        this.nft=nft;
        this.provider = provider
        this.currentAccount = await signer.getAddress()
        console.log('getting balance')
        this.balance=await nft.balanceOf(this.currentAccount)
        console.log('getting approval')
        this.isApproved=await nft.isApprovedForAll(this.currentAccount,this.contract.address)
        console.log(this.balance)
        console.log(this.isApproved)
      } catch (error) {
        console.log(error)
      }
    },
    approveNFT:async function(){
        await this.nft.setApprovalForAll(this.contract.address,true)
        this.isApproved=await this.nft.isApprovedForAll(this.currentAccount,this.contract.address)
    },
    mint:async function(){
        await this.nft.simpleMint(this.currentAccount)
    },
    joinGroup: async function () {
      let id =await this.nft.tokenByIndex(0)
      console.log(`the nft id is ${id}`)
      let r = await this.contract.addDAOIdentity(
        1,
        ethers.BigNumber.from(`0x${this.identity_commit.toString()}`),
        id
      )
      this.joinState = true
      this.isLoading = true // loading spinner
      setTimeout(() => {
          this.isLoading = false
      }, 10 * 1000)
      // console.log(await r.wait())
    },
    createProof: async function () {
      const circuitFilePath = 'http://localhost:8000/semaphore.wasm'
      const zkeyFilePath = 'http://localhost:8000/semaphore_final.zkey'
      let leaves = await this.contract.getGroupCommitments(1)

      leaves = leaves.map((element) => element._hex.slice(2))
      console.log(`leaves: ${leaves}`)

      const storageArtifacts = {
        leaves: leaves,
        depth: 20,
        leavesPerNode: 2,
      }

      try {
        // let proof = await this.client.semaphoreProof(
        //   '1',
        //   'something',
        //   circuitFilePath,
        //   zkeyFilePath,
        //   storageArtifacts,
        // )
        //
        // proof = JSON.parse(proof)
        // console.log('semaphore proof', proof.fullProof)
        // const params = {
        //   proof: proof.solidityProof,
        //   nullifierHash: proof.fullProof.publicSignals.nullifierHash.toString(),
        //   entityId: proof.fullProof.publicSignals.externalNullifier,
        //   challenge: 'something',
        // }
        //
        // console.log(params)
        // const hexified = new Buffer.from(JSON.stringify(params)).toString('hex')
        // this.proof = hexified
        // console.log(hexified)

        this.proof = "0x7b2270726f6f66223a5b22353432353232373033373035303334393431353934303039323538393138333439393230303338383831303731303036363236383733363637363733373235393035333537343132303639222c2234303339323330363730323239363838343035303934383834353137353238393932393639373437353532363937363133393833333431323034303737313236303230323135383635303031222c2231373130373533383030333931383033343230393538373337313631353932363530303135313937353031393339323233393638303835353434323339353034363436343333323938363839222c2234343237343239353639303939303132303736363932323235313333333534323836373236303332323930343936323539323036363433393239323735333236323338363135353836383738222c2232363830343632333430363739343733383938333530383637363238313132363036383236323939303135333535383433393935303633393537363131363231313533383630343239363332222c2233313635303130363236343133363532323833323038393938333232313536353534343838383638333631373639313131393537353836313835343339303735313031303235303131383838222c2234313733303339363636303231373031363632323631353338343431343237313739323839333335363838333037393638323035363038333033333238373035363031333639383635363130222c2237303434353834383830333032363338303837303930393635393232323533303139333733363131323234343733373535313534343039373536343131383237303637373331303533373833225d2c226e756c6c696669657248617368223a2239373433333534393632373136323530373139333238353736393235343834313839333733383232363739323237313338393339303532313937343733323335313831373933323038343032222c22656e746974794964223a2231222c226368616c6c656e6765223a226861686168616861227d"
        this.readMoreActivated = false
        this.$confetti.start();
        setTimeout(() => {
          this.$confetti.stop();
       }, 5000);
      } catch (e) {
        console.error(e)
      }
    },
  },
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
