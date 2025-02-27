
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 712 and 712+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'slate') and 
        (i_units = 'Carton' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'grey') and
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'violet') and
        (i_units = 'Gross' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'medium') and
        (i_units = 'Ton' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'goldenrod') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'seashell') and
        (i_units = 'Pound' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'burlywood') and
        (i_units = 'Tbl' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'firebrick') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
