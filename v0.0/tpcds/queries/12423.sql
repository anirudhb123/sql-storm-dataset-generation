
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 943 and 943+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'almond') and 
        (i_units = 'Dozen' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'blanched') and
        (i_units = 'Case' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'salmon') and
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'khaki') and
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'lavender') and 
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'chocolate') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'gainsboro') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'linen') and
        (i_units = 'Pound' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
