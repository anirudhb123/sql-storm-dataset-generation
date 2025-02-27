
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 680 and 680+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'aquamarine') and 
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'coral' or i_color = 'dim') and
        (i_units = 'Ounce' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'blush' or i_color = 'chiffon') and
        (i_units = 'Pound' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'royal' or i_color = 'peach') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'petite' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'burlywood') and 
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'hot') and
        (i_units = 'Dozen' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'sandy' or i_color = 'gainsboro') and
        (i_units = 'Unknown' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'beige') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'petite' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
