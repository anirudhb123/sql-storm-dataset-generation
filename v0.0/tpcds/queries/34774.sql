
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 795 and 795+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'gainsboro') and 
        (i_units = 'Bundle' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'azure' or i_color = 'magenta') and
        (i_units = 'Ounce' or i_units = 'Bunch') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'aquamarine') and
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'navajo') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'salmon' or i_color = 'brown') and 
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'drab') and
        (i_units = 'Ton' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'burnished') and
        (i_units = 'Carton' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'tan' or i_color = 'rosy') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
