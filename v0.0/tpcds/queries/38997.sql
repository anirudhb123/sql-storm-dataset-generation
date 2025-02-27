
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 839 and 839+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'plum') and 
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'seashell' or i_color = 'rose') and
        (i_units = 'Case' or i_units = 'N/A') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'coral') and
        (i_units = 'Gross' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'pale') and
        (i_units = 'Bunch' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'forest') and 
        (i_units = 'Ounce' or i_units = 'Cup') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'metallic') and
        (i_units = 'Bundle' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'brown' or i_color = 'sky') and
        (i_units = 'Unknown' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'deep') and
        (i_units = 'Gram' or i_units = 'Oz') and
        (i_size = 'large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
