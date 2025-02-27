
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 999 and 999+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'firebrick' or i_color = 'plum') and 
        (i_units = 'Bunch' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'rosy' or i_color = 'slate') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'misty' or i_color = 'olive') and
        (i_units = 'Pound' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'frosted' or i_color = 'floral') and
        (i_units = 'Lb' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cornflower' or i_color = 'turquoise') and 
        (i_units = 'Bundle' or i_units = 'Gross') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'sky' or i_color = 'almond') and
        (i_units = 'Tsp' or i_units = 'Box') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'light' or i_color = 'snow') and
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'maroon' or i_color = 'yellow') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
