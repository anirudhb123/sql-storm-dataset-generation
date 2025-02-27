
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 945 and 945+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'gainsboro' or i_color = 'deep') and 
        (i_units = 'Gross' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'maroon') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'steel') and
        (i_units = 'Lb' or i_units = 'Case') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'olive') and
        (i_units = 'Bunch' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chocolate' or i_color = 'metallic') and 
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'lace') and
        (i_units = 'Carton' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'firebrick') and
        (i_units = 'Each' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'cream' or i_color = 'dodger') and
        (i_units = 'Box' or i_units = 'N/A') and
        (i_size = 'N/A' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
