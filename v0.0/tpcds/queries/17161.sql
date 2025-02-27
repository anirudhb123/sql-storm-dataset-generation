
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 961 and 961+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'deep') and 
        (i_units = 'Pound' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'royal' or i_color = 'hot') and
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'medium') and
        (i_units = 'Pallet' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'dark') and
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'coral') and 
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'green') and
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'indian') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'beige') and
        (i_units = 'Tsp' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
