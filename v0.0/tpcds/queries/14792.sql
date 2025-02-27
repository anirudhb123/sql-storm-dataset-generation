
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 785 and 785+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'midnight' or i_color = 'light') and 
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'black' or i_color = 'mint') and
        (i_units = 'Carton' or i_units = 'Gram') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'frosted') and
        (i_units = 'Oz' or i_units = 'Gross') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'maroon') and
        (i_units = 'Dram' or i_units = 'Pallet') and
        (i_size = 'small' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'royal' or i_color = 'almond') and 
        (i_units = 'Ton' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'medium') and
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'medium' or i_size = 'extra large')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'lemon') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'purple') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
