
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 798 and 798+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'steel') and 
        (i_units = 'Cup' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'gainsboro' or i_color = 'drab') and
        (i_units = 'Gram' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'cornsilk') and
        (i_units = 'Lb' or i_units = 'Bundle') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'floral') and
        (i_units = 'Dozen' or i_units = 'Tbl') and
        (i_size = 'economy' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'blue') and 
        (i_units = 'Gross' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'metallic' or i_color = 'salmon') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'thistle') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'seashell') and
        (i_units = 'Dram' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
