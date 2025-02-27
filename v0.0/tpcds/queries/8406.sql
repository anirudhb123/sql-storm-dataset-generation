
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 755 and 755+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lemon' or i_color = 'almond') and 
        (i_units = 'Dram' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'yellow') and
        (i_units = 'Gross' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'white') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'ghost') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'black' or i_color = 'dodger') and 
        (i_units = 'Gram' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'hot') and
        (i_units = 'Unknown' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'plum') and
        (i_units = 'Bundle' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'spring' or i_color = 'ivory') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
