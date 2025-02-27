
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 757 and 757+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'black') and 
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'turquoise' or i_color = 'cyan') and
        (i_units = 'Bunch' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'ghost') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'mint') and
        (i_units = 'Ton' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'rose') and 
        (i_units = 'Ounce' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'light') and
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'linen') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'lace') and
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
