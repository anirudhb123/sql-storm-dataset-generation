
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 714 and 714+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'coral' or i_color = 'spring') and 
        (i_units = 'Carton' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'olive') and
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'navy') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'rosy') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'almond' or i_color = 'chartreuse') and 
        (i_units = 'Tbl' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'floral') and
        (i_units = 'Dozen' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'brown') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'bisque') and
        (i_units = 'Oz' or i_units = 'Ounce') and
        (i_size = 'large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
