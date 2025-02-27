
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 671 and 671+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'green') and 
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'goldenrod') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'hot') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'cornsilk') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'steel' or i_color = 'brown') and 
        (i_units = 'Each' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'lemon') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'ghost') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'cream') and
        (i_units = 'Bundle' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
