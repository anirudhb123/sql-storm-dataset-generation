
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 929 and 929+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'yellow') and 
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'rose') and
        (i_units = 'Dram' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'violet') and
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peach' or i_color = 'salmon') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'lace') and 
        (i_units = 'Pound' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'papaya') and
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'burlywood') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'peru') and
        (i_units = 'Bundle' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
