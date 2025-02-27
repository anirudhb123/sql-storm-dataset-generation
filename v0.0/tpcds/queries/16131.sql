
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 932 and 932+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'puff') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'cornsilk') and
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'pale') and
        (i_units = 'Box' or i_units = 'Tsp') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'khaki' or i_color = 'green') and
        (i_units = 'Ton' or i_units = 'Pound') and
        (i_size = 'large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'olive') and 
        (i_units = 'Dram' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'slate') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'hot') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'antique') and
        (i_units = 'Lb' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
