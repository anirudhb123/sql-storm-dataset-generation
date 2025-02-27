
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 942 and 942+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'tan' or i_color = 'brown') and 
        (i_units = 'Dozen' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'royal') and
        (i_units = 'Ton' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'frosted') and
        (i_units = 'N/A' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'seashell') and
        (i_units = 'Unknown' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'peru') and 
        (i_units = 'Tbl' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blush' or i_color = 'chocolate') and
        (i_units = 'Bunch' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'coral' or i_color = 'forest') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'pale') and
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
