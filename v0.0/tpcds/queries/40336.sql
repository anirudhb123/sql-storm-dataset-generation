
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 986 and 986+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'olive' or i_color = 'pale') and 
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'powder' or i_color = 'azure') and
        (i_units = 'Lb' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'moccasin' or i_color = 'gainsboro') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'linen') and
        (i_units = 'Oz' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'chocolate') and 
        (i_units = 'Gram' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'forest') and
        (i_units = 'N/A' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'smoke') and
        (i_units = 'Dram' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'dim') and
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
