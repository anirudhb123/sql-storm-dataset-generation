
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 944 and 944+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'spring' or i_color = 'burnished') and 
        (i_units = 'Gross' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'moccasin' or i_color = 'chiffon') and
        (i_units = 'Lb' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'peru' or i_color = 'frosted') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'papaya' or i_color = 'violet') and
        (i_units = 'Bundle' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornsilk' or i_color = 'deep') and 
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'brown') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'ghost') and
        (i_units = 'Cup' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'cornflower') and
        (i_units = 'Gram' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
