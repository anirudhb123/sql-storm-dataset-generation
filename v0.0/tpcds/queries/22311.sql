
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 772 and 772+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'moccasin' or i_color = 'lime') and 
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'red') and
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'dim') and
        (i_units = 'Pallet' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'almond') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lavender' or i_color = 'floral') and 
        (i_units = 'N/A' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'purple') and
        (i_units = 'Carton' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'royal') and
        (i_units = 'Cup' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'metallic') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
