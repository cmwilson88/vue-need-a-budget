update 
	transactions
set
	account_id = $1,
	trans_date = $2, 
	payee_id = $3, 
	spend_cat_id = $4,
	memo = $5, 
	outflow = $6, 
	inflow = $7,  
	type = $9,
	month = $11,
	year = $12,
	catgroup_act_id = $13
where id = $10;

update
    accounts
set
    amount = (select sum(outflow) + sum(inflow) from transactions where account_id = accounts.id)
where budget_id = $8;

update 
    spendcat_act sg
set
    activity = (
		select sum(outflow) + sum(inflow) from transactions t
		where spend_cat_id = $4
		and month = $11 and year = $12
        )
    where spendcat_id = $4 and month = $11 and year = $12;

-- update current spendcat avail based on previous month
do $$
begin
if $11 = 1 then
	update spendcat_avail sa
		set available = (
			select coalesce(
				(select available 
				from spendcat_avail 
					where month = 12 
						and year = $12 - 1 
						and spendcat_id = $4)
			, 0) 
		+ 
			(select budgeted + activity 
			from spendcat_act 
			where month = $11 
				and year = $12 
				and spendcat_id = $4)
		)
	where spendcat_id = $4 and month = $11 and year = $12;
else
	update spendcat_avail sa
		set available = (
			select coalesce(
				(select available 
				from spendcat_avail 
					where month = $11-1 
						and year = $12 
						and spendcat_id = $4)
			, 0) 
		+ 
			(select budgeted + activity 
			from spendcat_act 
			where month = $11 
				and year = $12 
				and spendcat_id = $4)
		)
	where spendcat_id = $4 and month = $11 and year = $12;
end if;
end
$$;

-- UPdate spendcat avail for next month
do $$
begin
if $11 = 12 then
	update spendcat_avail
		set available = (
			select coalesce(
				(select available
				from spendcat_avail 
					where spendcat_id = $4 
						and month = $11 
						and year = $12)
			,0) 
		+ 
			(select sum(budgeted) + sum(activity) 
			from spendcat_act 
			where spendcat_id = $4 
				and month = 1 
				and year = $12+1)
		)
	where spendcat_id = $4 and month = 1 and year = $12+1;
else 
	update spendcat_avail
		set available = (
			select coalesce(
				(select available
				from spendcat_avail 
					where spendcat_id = $4 
						and month = $11 
						and year = $12)
			,0) 
		+ 
			(select sum(budgeted) + sum(activity) 
			from spendcat_act 
			where spendcat_id = $4 
				and month = $11+1 
				and year = $12)
		)
	where spendcat_id = $4 and month = $11+1 and year = $12;
end if;
end
$$;

update catgroup_act  
	set activity = (
			select sum(sg.activity) from spendcat_act sg
			join spendcats s on sg.spendcat_id = s.id
			join catgroups c on c.id = s.catgroup_id
			join catgroup_act cg on c.id = cg.catgroup_id
			where sg.month = $11 and sg.year = $12
			and cg.id = $13
		)
	where catgroup_id = $14 and month = $11 and year = $12;


update catgroup_avail
	set available = (
			select sum(available) from spendcat_avail sa
			join spendcats s on sa.spendcat_id = s.id
			join catgroups c on c.id = s.catgroup_id
			where month = $11 and year = $12
			and catgroup_id = $14
		)
	where catgroup_id = $14 and month = $11 and year = $12;

-- UPdate next months category group
do $$
begin
if $11 = 12 then
	update catgroup_avail
		set available = (
				select sum(available) from spendcat_avail sa
				join spendcats s on sa.spendcat_id = s.id
				join catgroups c on c.id = s.catgroup_id
				where month = 1 and year = $12+1
				and catgroup_id = $14
			)
		where catgroup_id = $14 and month = 1 and year = $12+1;
else
	update catgroup_avail
		set available = (
				select sum(available) from spendcat_avail sa
				join spendcats s on sa.spendcat_id = s.id
				join catgroups c on c.id = s.catgroup_id
				where month = $11+1 and year = $12
				and catgroup_id = $14
			)
		where catgroup_id = $14 and month = $11+1 and year = $12;
end if;
end
$$;

update 
	budgets
set	
	to_be_budgeted = (
		select coalesce((select sum(inflow) 
		from transactions 
		where transactions.type = 'inflow' 
		and budget_id = $8
		), 0) - (
		select sum(cg.budgeted) from catgroups c
		join catgroup_act cg on cg.catgroup_id = c.id 
		where budget_id = $8
		))
where id = $8




-- update catgroup_act  
-- 	set activity = (
-- 			select sum(activity) from spendcat_act
-- 			where month = $11 and year = $12
-- 			and catgroup_act_id = $13
-- 		)
-- 	where catgroup_id = $13 and month = $11 and year = $12;

-- update catgroup_avail
-- set available = (select available from catgroup_avail where month = $11-1 and year = $12 and catgroup_id = $13) + (select budgeted + activity from catgroup_act where month = $11 and year = $12 and catgroup_id = $13)
-- where catgroup_id = $13 and month = $11 and year = $12;

-- update catgroup_avail
-- set available = (select available from catgroup_avail where month = $11 and year = $12 and catgroup_id = $13) + (select budgeted + activity from catgroup_act where month = $11+1 and year = $12 and catgroup_id = $13)
-- where catgroup_id = $13 and month = $11+1 and year = $12;

