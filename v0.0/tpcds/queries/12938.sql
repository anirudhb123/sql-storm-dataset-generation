
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 917 and 917+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'slate') and 
        (i_units = 'Dram' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'aquamarine') and
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'burnished') and
        (i_units = 'Bundle' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'metallic') and
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'almond' or i_color = 'grey') and 
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'lemon') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'orange') and
        (i_units = 'Box' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'lime' or i_color = 'hot') and
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
