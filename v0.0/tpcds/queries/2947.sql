
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 745 and 745+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'sienna') and 
        (i_units = 'Dram' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'grey') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'hot') and
        (i_units = 'Each' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'medium') and
        (i_units = 'Case' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'smoke') and 
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'dark') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'green') and
        (i_units = 'Pallet' or i_units = 'Carton') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'steel') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
