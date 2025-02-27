
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 713 and 713+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'indian') and 
        (i_units = 'Each' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'brown') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dodger') and
        (i_units = 'Gram' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'peach') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'rosy' or i_color = 'white') and 
        (i_units = 'Dram' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'midnight') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'thistle' or i_color = 'honeydew') and
        (i_units = 'Unknown' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'goldenrod') and
        (i_units = 'Carton' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
