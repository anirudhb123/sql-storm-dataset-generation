
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 871 and 871+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'metallic' or i_color = 'drab') and 
        (i_units = 'Gram' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'thistle' or i_color = 'powder') and
        (i_units = 'Each' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'white') and
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'peru') and
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'burnished') and 
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'wheat' or i_color = 'tomato') and
        (i_units = 'Pound' or i_units = 'Gross') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'khaki') and
        (i_units = 'Case' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'olive' or i_color = 'cornflower') and
        (i_units = 'Tsp' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
