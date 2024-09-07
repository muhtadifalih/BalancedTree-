-- Use a single SQL query to transform the product_hierarchy and product_prices datasets to the product_details table.

use balanced_tree ;

/*
select * from product_hierarchy; -- view

select * from product_prices ; -- view

select * from product_details ; -- view
*/

with cte5 as
(
with cte4 as
(
with cte3 as
(
with cte2 as
(
select 
	*
from product_hierarchy 
where parent_id in (1,2)
)
select
	a.id,
    a.parent_id,
    a.level_text as segment_name,
    b.level_text as style_name
from cte2 a
inner join product_hierarchy b
on a.id = b.parent_id
)
select
	a.id as segment_id,
    a.parent_id as category_id,
    a.segment_name,
    a.style_name,
    b.level_text as Category
from cte3 a
left join product_hierarchy b
on a.parent_id = b.id
)
select 
	concat(a.style_name,' ',a.segment_name,' - ',a.Category) as product_name,
    a.category_id,
    a.segment_id,
    b.id as style_id,
    a.Category as category_name,
    a.segment_name,
    a.style_name
from cte4 a
left join product_hierarchy b
on a.style_name = b.level_text
)
select
	b.product_id,
    b.price,
	a.*
from cte5 a
left join product_prices b
on a.style_id = b.id
;
