
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 752 and 752+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'smoke' or i_color = 'cornflower') and 
        (i_units = 'Tsp' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'metallic') and
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'honeydew') and
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'white') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'peru') and 
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'bisque' or i_color = 'lawn') and
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'sandy') and
        (i_units = 'N/A' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'tomato') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
