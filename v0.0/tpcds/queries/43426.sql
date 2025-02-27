
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 739 and 739+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'beige' or i_color = 'green') and 
        (i_units = 'Tsp' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'deep' or i_color = 'midnight') and
        (i_units = 'Oz' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'linen' or i_color = 'plum') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'cornflower' or i_color = 'floral') and
        (i_units = 'Lb' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'papaya' or i_color = 'cyan') and 
        (i_units = 'N/A' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'burnished' or i_color = 'seashell') and
        (i_units = 'Tbl' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'medium') and
        (i_units = 'Cup' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'violet' or i_color = 'forest') and
        (i_units = 'Case' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
