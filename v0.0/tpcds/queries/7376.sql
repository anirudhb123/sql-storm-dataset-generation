
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 726 and 726+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'black') and 
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'chocolate') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'linen') and
        (i_units = 'Unknown' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'dodger') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'cornsilk') and 
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'misty' or i_color = 'grey') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'purple') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'goldenrod' or i_color = 'snow') and
        (i_units = 'Dozen' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
