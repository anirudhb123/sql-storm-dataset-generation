
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 1000 and 1000+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'plum') and 
        (i_units = 'Carton' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'frosted' or i_color = 'peru') and
        (i_units = 'Each' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'drab') and
        (i_units = 'Gram' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'aquamarine' or i_color = 'ivory') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'violet') and 
        (i_units = 'Bundle' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'green' or i_color = 'lime') and
        (i_units = 'Ton' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'cornsilk') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'small' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'saddle') and
        (i_units = 'Pound' or i_units = 'Oz') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
