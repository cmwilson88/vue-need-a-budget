<template>
	<header class="accounts_header">

		<div class="accounts_header_top">
			<div class="accounts_header_total">
				<div class="accounts_header_total_inner">
					<div v-if="accountDisplayName" class="accounts_header_total_inner_label">
						{{accountDisplayName.name | capitalize-words}}
					</div>
					<div v-else class="accounts_header_total_inner_label">
						All Accounts
					</div>
					<div class="arrow"></div>
				</div>
			</div>
			<div class="accounts_header_balances">
				<div class="accounts_header_balances_cleared">
					<div class="accounts_header_balances_label">Cleared Balance</div>
					<span class="user_data">${{clearedBalance | amount-with-comma}}</span>
				</div>
				<i>+</i>
				<div class="accounts_header_balances_uncleared">
					<div class="accounts_header_balances_label">Uncleared Balance</div>
					<span class="user_data">${{unclearedBalance | amount-with-comma}}</span>
				</div>
				<i>=</i>
				<div class="accounts_header_balances_working">
					<div class="accounts_header_balances_label">Working Balance</div>
					<span class="user_data">${{workingBalance | amount-with-comma}}</span>
				</div>
			</div>
		</div>

		<div class="accounts_toolbar">
			<div class="accounts_toolbar_left">
				<button 
					@click="showModal=true"
					class="add_transaction button"
					style="cursor: pointer">
						<i class="icon add circle"></i>
						Add a transaction
				</button>
			</div>
		</div>

		<app-input-modal 
			v-if="showModal"
			@close="showModal=false"
			@submit="addNewTransaction">
			<h3 slot="header">Add New Transaction</h3>
			<div class="modal_inputs">
				<label for="account">Account:</label>
				<select name="account" v-model="newTransaction.account">
					<option selected disabled>Select an Account</option>
					<option 
						v-for="account in accounts"
						:value="account.id"
						key="account.id">{{account.name}}</option>
				</select>
				<br>
				<label for="date">Date:</label>
				<input type="date" v-model="newTransaction.date">
				<br>
				<label for="payee">Payee:</label>
				<select name="payees" v-model="newTransaction.payee">
					<option selected disabled>Select a Payee</option>
					<option 
						v-for="payee in payees"
						:value="payee.id"
						key="payee.id">{{payee.name}}</option>
				</select>
				<div class="payee_button_container">
					<button class="add_payee_button" @click="addPayeeStatus = true">
						<i class="icon add circle"></i>
						Add Payee
					</button>
				</div>
				<br>
				<label for="category">Category:</label>
				<select name="categories" v-model="newTransaction.category">
					<option selected disabled>Select a Category</option>
					<optgroup 
						v-for="item in categories"
						:label="item.budgetgroup.name">
							<option
								v-for="category in item.budgetgroup.subcategories"
								:value="category">{{category.name}}</option>
					</optgroup>
				</select>
				<br>
				<label for="memo">Memo:</label>
				<input type="text" v-model="newTransaction.memo">
				<br>
				<label for="outflow">Outflow:</label>
				<input type="number" v-model="newTransaction.outflow">
				<br>
				<label for="inflow">Inflow:</label>
				<input type="number" v-model="newTransaction.inflow">
				<br>
			</div>
		</app-input-modal>

		<app-input-modal v-if="addPayeeStatus" @close="addPayeeStatus = false" @submit="addNewPayee">
			<h3 slot="header">Add Payee</h3>
			<div class="modal_inputs">
				<label>Add New Payee:</label>
				<input type="text" v-model="newPayee.name">
			</div>
		</app-input-modal>
	</header>
</template>

<script>
	import axios from 'axios'
	import InputModal from '../InputModals/InputModal.vue'
	import {mapGetters, mapActions} from 'vuex'
	export default {
		data() {
			return {
				showModal: false,
				addPayeeStatus: false,
				accountPath: this.$route.params.acc_id,
				newPayee: {
					name: ''
				},
				newTransaction: {
					account: '',
					date: '',
					payee: '',
					category: '',
					memo: '',
					outflow: null, 
					inflow: null
				}
			}
		},
		computed: {
			...mapGetters(['accountDisplayName', 'filteredTransactions']),
			clearedBalance: function() {
				let cleared = this.filteredTransactions.filter(transaction => transaction.cleared)
				let sumOutflow = cleared.reduce((a,b) => a + b.outflow*1, 0)
				let sumInflow = cleared.reduce((a,b) => a + b.inflow*1, 0)
				return sumInflow + sumOutflow
			},
			unclearedBalance: function() {
				let uncleared = this.filteredTransactions.filter(transaction => !transaction.cleared)
				let sumOutflow = uncleared.reduce((a,b) => a + b.outflow*1, 0)
				let sumInflow = uncleared.reduce((a,b) => a + b.inflow*1, 0)
				return sumInflow + sumOutflow
			},
			workingBalance: function() {
				return this.clearedBalance + this.unclearedBalance
			},
			accounts: function() {
				return this.$store.state.accounts
			},
			payees: function() {
				return this.$store.state.payees
			},
			categories: function() {
				return this.$store.state.categories
			}
		},
		watch: {
			'$route': function() {
				this.accountPath = this.$route.params.acc_id
			}
		},
		methods: {
			...mapActions(['getTransactions', 'getAccounts', 'getPayees']),
			addNewTransaction() {
				if(this.newTransaction.category.type === 'inflow') {
					let month = this.newTransaction.date.split('-')[1];
					let year = this.newTransaction.date.split('-')[0];	
					axios.post(
						'/api/' + this.$route.params.b_id + '/transactions/inflow',
						{
							account: this.newTransaction.account,
							date: this.newTransaction.date,
							payee: this.newTransaction.payee,
							category: this.newTransaction.category.id,
							memo: this.newTransaction.memo,
							outflow: Number(this.newTransaction.outflow)*-1,
							inflow: Number(this.newTransaction.inflow),
							type: this.newTransaction.category.type,
							month: month,
							year: year,
							catgroup_act_id: this.newTransaction.category.catgroup_act_id,
							catgroup_id: this.newTransaction.category.catgroup_id
						}
					).then(response => {
						console.log('inflow post successful')
						this.getTransactions();
						this.getAccounts();
					})
				} else {
					let month = this.newTransaction.date.split('-')[1];
					let year = this.newTransaction.date.split('-')[0];	
					axios.post('/api/' 
						+ this.$route.params.b_id + '/transactions/new',
						{
							account: this.newTransaction.account,
							date: this.newTransaction.date,
							payee: this.newTransaction.payee,
							category: this.newTransaction.category.id,
							memo: this.newTransaction.memo,
							outflow: Number(this.newTransaction.outflow)*-1,
							inflow: Number(this.newTransaction.inflow),
							type: this.newTransaction.category.type,
							month: month,
							year: year,
							catgroup_act_id: this.newTransaction.category.catgroup_act_id,
							catgroup_id: this.newTransaction.category.catgroup_id
						}
					).then(() => {
						console.log('post request successful')
						this.getTransactions()
						this.getAccounts()
					})
				}
				this.cancelNewTransaction()
			},
			cancelNewTransaction() {
				this.showModal = false;
				this.newTransaction.account = '';
				this.newTransaction.date = '';
				this.newTransaction.payee = '';
				this.newTransaction.category = '';
				this.newTransaction.memo = '';
				this.newTransaction.outflow = null; 
				this.newTransaction.inflow = null;
			},
			addNewPayee() {
				axios.post('/api/' + this.$route.params.b_id + '/payees/new', 
					{
						name: this.newPayee.name 
					}
				).then(response => {
					console.log('new payee added')
					this.getPayees();
					this.addPayeeStatus = false
				})
			}
		},
		components: {
			appInputModal: InputModal
		}
	}
</script>

<style>
	.accounts_header {
		flex: 0 0 auto;
		position: inherit;
		top: 0;
		left: 260px;
		right: 0;
		width: inherit;
		min-width: 838px;
		height: 6.2em;
		border-bottom: 1px solid #042229;
		color: #fff;
		background-color: #003540;
		font-weight: bold;
		overflow: visible;
		z-index: 11;
	}

	.accounts_header .accounts_header_top {
		display: flex;
		align-items: flex-start;
	}

	.accounts_header .accounts_header_total {
		padding: 0;
		flex: 0 1 auto;
	}

	.accounts_header .accounts_header_total_inner {
		position: relative;
		float: left;
		margin: .5em .75em .65em .5em;
		border-radius: .4em;
		background-color: #16a336;
		color: #fff;
		text-align: center;
		padding: .2em;
		font-size: 1.3125em;
		line-height: 1em;
	}

	.accounts_header
	.accounts_header_total_inner
	.accounts_header_total_inner_label {
		margin: 0 auto;
		padding: .3em .25em;
		font-size: 1em;
		font-weight: 300;
		color: #fff;
		max-width: 300px;
		text-overflow: ellipsis;
		overflow: hidden;
		white-space: nowrap;
	}

	.accounts_header
	.accounts_header_total_inner
	.arrow {
		position: absolute;
		border-top: .5em solid transparent;
		border-bottom: .5em solid transparent;
		border-left: .5em solid #16a336;
		top: 50%;
		margin-top: -.5em;
		right: -.45em;
	}

	.accounts_header .accounts_header_balances {
		flex: 1 1 auto;
		display: flex;
		font-size: 1.1rem;
		overflow: hidden;
	}

	.accounts_header .accounts_header_balances_cleared,
	.accounts_header .accounts_header_balances_uncleared,
	.accounts_header .accounts_header_balances_working {
		flex: 0 1 auto;
		overflow: hidden;
		margin-top: .75em;
		text-align: center;
		color: #5bbe72;
	}

	.accounts_header .accounts_header_balances_label {
		font-style: italic;
		font-weight: normal;
		font-size: .7em;
		color: #fff;
	}

	.accounts_header .accounts_header_balances i {
		flex: 0 0 auto;
		display: block;
		color: #588697;
		font-size: 1em;
		font-style: normal;
		padding: 1.125em .5em 0 .5em;
	}

	.accounts_toolbar {
		background-color: #fff;
		border-bottom: 1px solid #dfe4e9;
		font-size: .8em;
		width: 100%;
		height: 2.95em;
		padding-top: .25em;
		clear: both;
	}

	.accounts_toolbar .accounts_toolbar_left {
		float: left;
		padding-left: .5em;
		width: 31rem;
	}

	.accounts_toolbar .button {
		display: flex;
		align-items: center;
		height: 2.2em;
		border: none;
	}

	.accounts_toolbar .button:hover {
		background-color: transparent;
		color: #005076;
	}

	.payee_button_container {
		display: flex;
		justify-content: center;
		margin-top: 15px;
	}

	.add_payee_button {
		background-color: rgba(255,255,255,0.2);
		border: none;
		width: 75%;
		border-radius: 1000px;
		box-shadow: none;
		padding: .3em .6em .4em .4em;
		font-size: .8em;
		line-height: 1em;
		float: right;
		color: #fff;
	}

</style>