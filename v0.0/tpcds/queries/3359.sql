
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 872 and 872+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dodger' or i_color = 'chiffon') and 
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'yellow' or i_color = 'black') and
        (i_units = 'Oz' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'burlywood') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'pale') and
        (i_units = 'Gram' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'dark' or i_color = 'sky') and 
        (i_units = 'Lb' or i_units = 'Dozen') and
        (i_size = 'N/A' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'maroon' or i_color = 'chartreuse') and
        (i_units = 'Bunch' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'rose' or i_color = 'forest') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'drab' or i_color = 'linen') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
