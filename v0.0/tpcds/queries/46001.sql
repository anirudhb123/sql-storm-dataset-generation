
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 852 and 852+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'dark') and 
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'lime') and
        (i_units = 'Ton' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'cream') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'saddle') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'chocolate') and 
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'red' or i_color = 'black') and
        (i_units = 'Tbl' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'slate') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'frosted') and
        (i_units = 'Pallet' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
