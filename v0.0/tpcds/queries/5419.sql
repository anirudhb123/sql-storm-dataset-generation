
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 930 and 930+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'azure') and 
        (i_units = 'Gram' or i_units = 'N/A') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'forest') and
        (i_units = 'Bundle' or i_units = 'Carton') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'powder') and
        (i_units = 'Oz' or i_units = 'Box') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dark' or i_color = 'salmon') and
        (i_units = 'Pallet' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'green' or i_color = 'purple') and 
        (i_units = 'Gross' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'chiffon' or i_color = 'beige') and
        (i_units = 'Each' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'dim') and
        (i_units = 'Dozen' or i_units = 'Case') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'deep' or i_color = 'turquoise') and
        (i_units = 'Pound' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
