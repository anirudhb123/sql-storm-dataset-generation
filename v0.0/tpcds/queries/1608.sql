
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 932 and 932+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burlywood' or i_color = 'linen') and 
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'dim' or i_color = 'blush') and
        (i_units = 'Box' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'sandy') and
        (i_units = 'Dozen' or i_units = 'Pallet') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'thistle') and
        (i_units = 'Cup' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'plum' or i_color = 'powder') and 
        (i_units = 'Gross' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'midnight') and
        (i_units = 'Dram' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'pink' or i_color = 'saddle') and
        (i_units = 'Tsp' or i_units = 'Gram') and
        (i_size = 'large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'peach') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
