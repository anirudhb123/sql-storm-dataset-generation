
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 987 and 987+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'chartreuse') and 
        (i_units = 'Tbl' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'floral' or i_color = 'chiffon') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'mint' or i_color = 'thistle') and
        (i_units = 'Gross' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'linen') and
        (i_units = 'Ounce' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'olive') and 
        (i_units = 'Tsp' or i_units = 'Case') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'almond' or i_color = 'navy') and
        (i_units = 'Gram' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'antique' or i_color = 'spring') and
        (i_units = 'Bundle' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'white' or i_color = 'forest') and
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
