
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 842 and 842+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'forest') and 
        (i_units = 'Pallet' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'papaya' or i_color = 'tan') and
        (i_units = 'Box' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'pale') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'chartreuse') and
        (i_units = 'Gram' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'blush') and 
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'drab' or i_color = 'wheat') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'black') and
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'rosy' or i_color = 'midnight') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
