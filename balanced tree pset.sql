-- HIGH LEVEL SALES ANALYSIS

-- CLEANING THE SALES TABLE
use balanced_tree ; -- selecting database

drop table if exists sales_cln ;
create table sales_cln
select
	sales.prod_id,
	sales.qty,
    sales.price,
    sales.discount,
    round((sales.discount / 100 ) * sales.price,2) as discount_amount,
	round((1-(sales.discount/100)) * sales.price,2) as price_after_discount, 
    case when member = 't' then 'Yes' else 'No' end as member_status,
    sales.txn_id,
    sales.start_txn_time
from sales  
;

select * from sales_cln limit 10 offset 500 ;

-- What was the total quantity sold for all products?

select
	prod_id,
	sum(qty) as sum_sold,
    dense_rank() over(order by sum(qty) desc) as rnk
from sales_cln
group by 1
; #TABLE FOR QUESTION #1 - HIGH LEVEL ANALYSIS
    
-- What is the total generated revenue for all products before discounts?

-- select * from sales_cln limit 10 offset 500 ;

select
	sum(price)as revenue
from sales_cln
; #TABLE FOR QUESTION #2 - HIGH LEVEL ANALYSIS

-- What was the total discount amount for all products?
select
	sum(sales_cln.discount_amount) as sum_discount
from sales_cln
; #TABLE FOR QUESTION #3 - HIGH LEVEL ANALYSIS

select 
(
select
	sum(price)as revenue
from sales_cln) 
-
(
select
	sum(sales_cln.discount_amount) as sum_discount
from sales_cln
)  
as earning_after_discount
;

-- Transaction Analysis
-- How many unique transactions were there?

create view sales_column as
select * from sales_cln limit 10 offset 500 ; 

select count(distinct txn_id) as txn from sales_cln ; -- table for question #1 Transaction Analysis

-- amount revenue by txn_id
select 
	txn_id,
	sum(price_after_discount),
    rank() over (order by  sum(price_after_discount) desc) as rnk
from sales_cln
group by 1
;

-- What is the average unique products purchased in each transaction?

select * from sales_column ; # was trying to start using VIEW command

select
	avg(unique_prod)
from
(
select
	txn_id,
	count( distinct prod_id) as unique_prod
from sales_cln
group by 1
) 
as unique_prod_in_txn
; # -- table for question #2 Transaction Analysis - 6.03 products per transaction 

-- What are the 25th, 50th and 75th percentile values for the revenue per transaction?
/*select
	txn_id,
    sum_rev,
    rnk
from*/

with cte 
as
(
select
	txn_id,
    case when rnk <= 0.25 * total_txn then sum_rev end as twentyfivep,
    case when rnk <= 0.5 * total_txn then sum_rev  end as fiftyp,
    case when rnk <= 0.75 * total_txn then sum_rev  end as seventyfivep
from
(
select
	txn_id,
	sum(price_after_discount) as sum_rev,
    count(txn_id) over() as total_txn,
    row_number () over(order by sum(price_after_discount)) as rnk
    -- round(percent_rank() over(order by sum(price_after_discount)),3) as rnk_percent
from sales_cln
group by 1
) 
as ordered
)
select 
	max(twentyfivep) as '25th',  -- 25th percentile
    max(fiftyp) as '50th', -- 50th percentile
    max(seventyfivep) as '75th' -- 75th percentile
from cte 
;

-- What is the average discount value per transaction?

select * from sales_column ; -- view

select 
	txn_id,
	avg(discount_amount) as avg_disc_value,
    rank() over(order by avg(discount_amount) desc) as rnk
from sales_cln
-- where txn_id = '5428c6'
group by 1
; # by discount in usd

-- What is the percentage split of all transactions for members vs non-members?

select
	count(distinct txn_id) as count_trx,
	count(distinct case when member_status = 'Yes' then txn_id else null end) as member_trx,
    count(distinct case when member_status = 'Yes' then txn_id else null end) / count(distinct txn_id) as member_ptage,
    count(distinct case when member_status = 'No' then txn_id else null end) as nonmember_trx,
    count(distinct case when member_status = 'No' then txn_id else null end) / count(distinct txn_id) as nonmember_ptage
from sales_cln
; # 60% for members else non-members

-- What is the average revenue for member transactions and non-member transactions?

select
	round(avg(case when member_status = 'Yes' then price_after_discount else null end),2) as members_rev,
    round(avg(case when member_status = 'No' then price_after_discount else null end),2) as nonmembers_rev
from sales_cln 
; # 25.12 for members, 24.79 for nonmembers


-- PRODUCT LEVEL ANALYSIS

-- What are the top 3 products by total revenue before discount?

select
	product_rev_ranked.*
from 
(
select
	prod_id,
    sum(price),
    rank() over(order by sum(price) desc) as rnk
from sales_cln 
group by 1
)
as product_rev_ranked 
where product_rev_ranked.rnk in (1,2,3)
;

-- What is the total quantity, revenue and discount for each segment?

select * from sales_column ;

select * from product_details limit 10 ; 

SELECT
	b.segment_name,
	sum(a.qty) as sum_qty,
    sum(a.price) as sum_rev,
    round(sum(a.discount_amount))as sum_discount
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by b.segment_name
;

-- What is the top selling product for each segment?

with cte as
(
SELECT
	b.segment_name,
	b.product_name,
	-- sum(a.qty) as sum_qty,
    sum(a.price) as sum_rev,
    rank() over(partition by segment_name order by sum(a.price) desc) as rnk
    -- round(sum(a.discount_amount))as sum_discount
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by b.segment_name,b.product_name
)
select 
	cte.*
from cte
	where rnk = 1
;

-- What is the total quantity, revenue and discount for each category?

SELECT
	b.category_name,
	sum(a.qty) as sum_qty,
    sum(a.price) as sum_rev,
    round(sum(a.discount_amount))as sum_discount
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by b.category_name
;

-- What is the top selling product for each category?

with cte as 
(
select
	b.category_name,
	b.product_name,
	sum(a.price) as sum_revenue,
    rank() over(partition by b.category_name order by sum(a.price) desc) as rnk

from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by 1,2
)
select 
	cte.*
from cte
where rnk = 1
;

-- What is the percentage split of revenue by product for each segment?

with cte
as
(
select
	-- b.product_name,
	b.segment_name,
    sum(a.price) as rev_segment
    -- sum(a.price) over() as total_rev
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by 1
)
select
	cte.segment_name,
    cte.rev_segment,
    sum(rev_segment) over() as total_rev,
    (cte.rev_segment / sum(rev_segment) over())*100 as ptage
from cte
;

-- What is the percentage split of revenue by segment for each category?

with cte 
as
(
select
	b.segment_name,
    b.category_name,
    sum(a.price) as rev

from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by 1,2
)
select
	cte.*,
    sum(rev) over(partition by cte.category_name) as total_per_category,
	case 
		when cte.category_name = 'Mens' then cte.rev/sum(rev) over(partition by cte.category_name)
        when cte.category_name = 'Womens' then cte.rev/sum(rev) over(partition by cte.category_name)
        else null end
        as percentage
from cte
;

-- What is the percentage split of total revenue by category?

with cte 
as
(
select
	b.category_name,
	sum(a.price) as revenue
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by 1
)
select 
	cte.*,
    sum(cte.revenue) over() as total,
    cte.revenue/sum(cte.revenue) over() as percentage
from cte
;

-- What is the total transaction “penetration” for each product? 
-- penetration = number of transactions where at least 1 quantity of a product was purchased divided by total number of transactions)

-- find distinct count of transactions
select
	count( distinct txn_id) as ct_dis
from sales_cln 
;

-- use pivot to find penetration

select
	b.product_id,
	count(distinct a.txn_id) as txn,
    case
		when b.product_id = '2a2353' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = '2feb6b' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = '5d267b' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = '72f5d4' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = '9ec847' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = 'b9a74d' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
		when b.product_id = 'c4a632' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = 'c8d436' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = 'd5e9a6' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = 'e31d39' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = 'e83aa3' then count(distinct a.txn_id) / ( select count( distinct txn_id) from sales_cln)
        when b.product_id = 'f084eb' then count(distinct a.txn_id)/ ( select count( distinct txn_id) from sales_cln)
        else 'Check!'
        end as penetration
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by 1
;

-- What is the most common combination of at least 1 quantity of any 3 products in a 1 single transaction?
-- find top three most purchased items

select * from sales_cln ;

select
	b.product_id,
	count(distinct a.txn_id) as txn,
    rank() over(order by count(distinct a.txn_id) desc) as rnk
from sales_cln a
left join product_details b
on a.prod_id = b.product_id
group by 1
limit 3
;

-- find unique txn_id table
create temporary table unique_txn
select
	distinct txn_id
from sales_cln
;

select * from unique_txn ;

-- find txn for product #1
create temporary table p1
select
	txn_id,
	prod_id

from sales_cln
where prod_id in ('f084eb')
;

-- find txn for product #2
create temporary table p2
select
	txn_id,
	prod_id

from sales_cln
where prod_id in ('9ec847')
;

-- find txn for product #3
create temporary table p3
select
	txn_id,
	prod_id

from sales_cln
where prod_id in ('c4a632')
;

-- find txn for product #1
create temporary table p1
select
	txn_id,
	prod_id

from sales_cln
where prod_id in ('f084eb')
;

-- find txn for product #2
create temporary table p2
select
	txn_id,
	prod_id

from sales_cln
where prod_id in ('9ec847')
;

-- find txn for product #3
create temporary table p3
select
	txn_id,
	prod_id

from sales_cln
where prod_id in ('c4a632')
;



-- join the tables
with cte 
as
(
select
	a.txn_id,
    b.txn_id p1,
    c.txn_id p2,
    d.txn_id p3,
    case
		when b.txn_id is not null and c.txn_id is not null then 'p1-p2'
        when c.txn_id is not null and d.txn_id is not null then 'p2-p3'
        when b.txn_id is not null and d.txn_id is not null then 'p1-p3'
        else 'not a combination'
        end as
        flag

from unique_txn a
left join p1 b
on a.txn_id = b.txn_id 
left join p2 c
on a.txn_id = c.txn_id 
left join p3 d
on a.txn_id = d.txn_id 
)

select 
	flag,
    count(txn_id) as count_txn
from cte
group by flag
; -- the most common combination in one transaction is products 1 and products 2
