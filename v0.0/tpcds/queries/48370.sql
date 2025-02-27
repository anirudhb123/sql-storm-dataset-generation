
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 694 and 694+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'frosted' or i_color = 'burnished') and 
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'papaya') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'dim') and
        (i_units = 'N/A' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'grey') and
        (i_units = 'Tsp' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'hot') and 
        (i_units = 'Tbl' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'plum' or i_color = 'royal') and
        (i_units = 'Bundle' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'peach') and
        (i_units = 'Carton' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'floral') and
        (i_units = 'Case' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
