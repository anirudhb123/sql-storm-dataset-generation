
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 988 and 988+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'hot' or i_color = 'gainsboro') and 
        (i_units = 'N/A' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'chocolate') and
        (i_units = 'Bunch' or i_units = 'Gram') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'forest') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'indian') and
        (i_units = 'Pallet' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'orange') and 
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'beige' or i_color = 'bisque') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'thistle') and
        (i_units = 'Ton' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'orchid') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
