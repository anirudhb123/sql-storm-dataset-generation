
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 683 and 683+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'bisque' or i_color = 'burnished') and 
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'blanched' or i_color = 'almond') and
        (i_units = 'Tsp' or i_units = 'Unknown') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'saddle') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'blush') and
        (i_units = 'Ounce' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'light' or i_color = 'blue') and 
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'salmon') and
        (i_units = 'Carton' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'linen') and
        (i_units = 'Tbl' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'ghost' or i_color = 'grey') and
        (i_units = 'Oz' or i_units = 'Dram') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
