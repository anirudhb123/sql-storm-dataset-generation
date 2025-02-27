
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 797 and 797+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'linen') and 
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'burnished') and
        (i_units = 'Ton' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'slate') and
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'seashell' or i_color = 'steel') and
        (i_units = 'Unknown' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'brown') and 
        (i_units = 'Gram' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'beige') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'blue') and
        (i_units = 'Pallet' or i_units = 'Dram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'frosted') and
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
