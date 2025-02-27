
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 697 and 697+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'pale') and 
        (i_units = 'N/A' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'sandy') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'cornsilk') and
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'powder') and
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blue' or i_color = 'red') and 
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'rosy') and
        (i_units = 'Each' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'beige') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'burnished') and
        (i_units = 'Gram' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
