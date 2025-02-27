
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 823 and 823+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'mint' or i_color = 'seashell') and 
        (i_units = 'Each' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'tan' or i_color = 'navajo') and
        (i_units = 'Box' or i_units = 'Unknown') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'burnished') and
        (i_units = 'Dram' or i_units = 'Pound') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'lace' or i_color = 'hot') and
        (i_units = 'Lb' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'small')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'linen' or i_color = 'violet') and 
        (i_units = 'Dozen' or i_units = 'Ounce') and
        (i_size = 'extra large' or i_size = 'small')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'powder') and
        (i_units = 'Oz' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'beige' or i_color = 'midnight') and
        (i_units = 'Cup' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'salmon' or i_color = 'white') and
        (i_units = 'Gross' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'small')
        )))) > 0
 order by i_product_name
 limit 100;
