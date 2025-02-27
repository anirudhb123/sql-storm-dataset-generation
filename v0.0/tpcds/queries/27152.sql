
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 799 and 799+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'sky' or i_color = 'sandy') and 
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'chartreuse' or i_color = 'navy') and
        (i_units = 'Case' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'pink') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'cyan') and
        (i_units = 'Carton' or i_units = 'Box') and
        (i_size = 'medium' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'drab') and 
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'medium' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'snow' or i_color = 'blanched') and
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'lawn') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'burnished') and
        (i_units = 'Each' or i_units = 'Ounce') and
        (i_size = 'medium' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
