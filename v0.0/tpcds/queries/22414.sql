
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 781 and 781+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'moccasin' or i_color = 'saddle') and 
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'wheat') and
        (i_units = 'Box' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'puff') and
        (i_units = 'Each' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornsilk' or i_color = 'pale') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'navy' or i_color = 'frosted') and 
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'medium') and
        (i_units = 'Case' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lemon' or i_color = 'metallic') and
        (i_units = 'Tsp' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'cornflower') and
        (i_units = 'Unknown' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
