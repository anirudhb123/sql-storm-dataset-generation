
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 697 and 697+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'floral' or i_color = 'brown') and 
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'peru') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'almond') and
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'cornflower') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'papaya') and 
        (i_units = 'Ton' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'puff') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'slate') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'ivory') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
