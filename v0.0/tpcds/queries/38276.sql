
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 928 and 928+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'pink') and 
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'cornsilk') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'beige') and
        (i_units = 'Dram' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'brown') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'lime') and 
        (i_units = 'Gross' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'slate') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'chiffon') and
        (i_units = 'Cup' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dodger') and
        (i_units = 'Pallet' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
