
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 902 and 902+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'violet') and 
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'navy' or i_color = 'tomato') and
        (i_units = 'Box' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'burnished') and
        (i_units = 'Bunch' or i_units = 'Cup') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'floral') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'dim') and 
        (i_units = 'Carton' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'green') and
        (i_units = 'Case' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'turquoise' or i_color = 'papaya') and
        (i_units = 'Dozen' or i_units = 'Bundle') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lawn' or i_color = 'azure') and
        (i_units = 'Ton' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
