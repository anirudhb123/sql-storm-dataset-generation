
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 712 and 712+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dim' or i_color = 'coral') and 
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'snow' or i_color = 'ghost') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'almond') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'misty') and
        (i_units = 'Ounce' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'red' or i_color = 'linen') and 
        (i_units = 'Pallet' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornsilk' or i_color = 'slate') and
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'burnished') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'lime') and
        (i_units = 'Bunch' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
