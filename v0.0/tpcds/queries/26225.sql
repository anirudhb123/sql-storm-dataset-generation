
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 698 and 698+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'drab') and 
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'blush') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'rose') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'papaya') and
        (i_units = 'Unknown' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'burlywood') and 
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'salmon') and
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'rosy') and
        (i_units = 'Tbl' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'dark') and
        (i_units = 'Lb' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
