
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 710 and 710+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'seashell') and 
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'drab') and
        (i_units = 'Tbl' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'peru') and
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'powder') and
        (i_units = 'Gram' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'khaki' or i_color = 'brown') and 
        (i_units = 'N/A' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'almond') and
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'lime') and
        (i_units = 'Bundle' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'dim') and
        (i_units = 'Dozen' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
