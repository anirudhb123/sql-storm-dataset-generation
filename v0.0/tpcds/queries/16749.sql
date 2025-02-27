
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 915 and 915+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navajo' or i_color = 'almond') and 
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'dark') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'forest') and
        (i_units = 'Pound' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'chiffon') and
        (i_units = 'Oz' or i_units = 'Bundle') and
        (i_size = 'petite' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blush' or i_color = 'plum') and 
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'dodger') and
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'rose') and
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'metallic') and
        (i_units = 'N/A' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
