
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 901 and 901+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'metallic') and 
        (i_units = 'Case' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'mint') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'ivory') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'lavender') and
        (i_units = 'N/A' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'peru' or i_color = 'cornflower') and 
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'indian' or i_color = 'wheat') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'purple' or i_color = 'dim') and
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'economy' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'sandy') and
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
