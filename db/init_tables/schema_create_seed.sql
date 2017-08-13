DROP TABLE IF EXISTS users CASCADE;
DROP TABLE IF EXISTS budgets CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS payees CASCADE;
DROP TABLE IF EXISTS catgroups CASCADE;
DROP TABLE IF EXISTS spendcats CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;


-- Users
CREATE TABLE IF NOT EXISTS Users (
	id serial primary key,
	first_name text not null,
	last_name text not null,
	email text unique not null,
	password text not null
);

-- Budgets
CREATE TABLE IF NOT EXISTS Budgets (
	id serial primary key,
	name text not null,
	user_id integer not null,
	foreign key (user_id) references Users(id)
);

-- Accounts
CREATE TABLE IF NOT EXISTS Accounts (
	id serial primary key,
	name text not null,
	type text not null,
	amount decimal(11,2) not null,
	uncleared decimal(11,2),
	cleared decimal(11,2),
	working decimal(11,2),
	budget_id integer not null,
	foreign key (budget_id) references Budgets(id)
);

-- Payees
CREATE TABLE IF NOT EXISTS Payees (
	id serial primary key,
	name text not null,
	budget_id integer not null,
	foreign key (budget_id) references Budgets(id)
);

-- Category Groups
CREATE TABLE IF NOT EXISTS CatGroups (
	id serial primary key,
	name text not null,
	month integer not null,
	year integer not null,
	budgeted decimal(9,2) default 0.00,
	activity decimal(9,2) default 0.00,
	available decimal(9,2) default 0.00,
	budget_id integer not null,
	foreign key (budget_id) references Budgets(id)
);

-- Spending Groups
CREATE TABLE IF NOT EXISTS SpendCats (
	id serial primary key,
	name text not null,
	month integer not null,
	year integer not null,
	budgeted decimal(9,2) default 0,
	activity decimal(9,2) default 0,
	available decimal(9,2) default 0,
	catgroup_id integer not null,
	budget_id integer not null,
	foreign key (catgroup_id) references CatGroups(id),
	foreign key (budget_id) references Budgets(id)
);

-- Transactions
CREATE TABLE IF NOT EXISTS Transactions (
	id serial primary key,
	trans_date text not null,
	account_id integer not null,
	payee_id integer not null,
	spend_cat_id integer not null,
	memo text default null,
	outflow decimal(9,2) default 0,
	inflow decimal(9,2) default 0,
	cleared boolean default FALSE,
	budget_id integer not null,
	foreign key (account_id) references Accounts(id),
	foreign key (payee_id) references Payees(id),
	foreign key (spend_cat_id) references SpendCats(id),
	foreign key (budget_id) references Budgets(id)
);