
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 912 and 912+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'gainsboro') and 
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'aquamarine' or i_color = 'pale') and
        (i_units = 'Bunch' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'slate' or i_color = 'midnight') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'beige') and
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'steel') and 
        (i_units = 'Unknown' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'ivory' or i_color = 'seashell') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'cream') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'blue') and
        (i_units = 'Dozen' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
