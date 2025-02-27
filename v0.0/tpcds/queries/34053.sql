
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 884 and 884+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'yellow' or i_color = 'cyan') and 
        (i_units = 'Bunch' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'magenta' or i_color = 'metallic') and
        (i_units = 'Pallet' or i_units = 'Ton') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'azure') and
        (i_units = 'Box' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'burlywood' or i_color = 'papaya') and
        (i_units = 'Ounce' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'sky') and 
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'lemon') and
        (i_units = 'Cup' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'plum') and
        (i_units = 'Oz' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'cornflower') and
        (i_units = 'Each' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
