
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 968 and 968+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'chartreuse') and 
        (i_units = 'Lb' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'dim') and
        (i_units = 'Pallet' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'drab') and
        (i_units = 'Dozen' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'metallic') and
        (i_units = 'Carton' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'rosy') and 
        (i_units = 'Pound' or i_units = 'Case') and
        (i_size = 'medium' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lemon' or i_color = 'pink') and
        (i_units = 'Tsp' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'dodger') and
        (i_units = 'Box' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'violet') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
