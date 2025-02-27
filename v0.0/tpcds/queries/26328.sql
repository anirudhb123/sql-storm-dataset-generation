
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 960 and 960+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'mint') and 
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'pale' or i_color = 'peach') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'sandy') and
        (i_units = 'Dozen' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'green') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'N/A' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'ghost') and 
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'cyan') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'smoke') and
        (i_units = 'Cup' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'blush') and
        (i_units = 'N/A' or i_units = 'Lb') and
        (i_size = 'N/A' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
