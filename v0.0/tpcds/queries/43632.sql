
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 929 and 929+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'lime') and 
        (i_units = 'Case' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'navajo' or i_color = 'green') and
        (i_units = 'Dram' or i_units = 'Ton') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'snow' or i_color = 'magenta') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'cyan') and
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'brown' or i_color = 'honeydew') and 
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'salmon' or i_color = 'azure') and
        (i_units = 'N/A' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orange' or i_color = 'antique') and
        (i_units = 'Pallet' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'grey') and
        (i_units = 'Bunch' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
