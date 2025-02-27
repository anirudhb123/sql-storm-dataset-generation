
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 725 and 725+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'forest' or i_color = 'lemon') and 
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'firebrick' or i_color = 'red') and
        (i_units = 'Cup' or i_units = 'Ounce') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'smoke') and
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'floral' or i_color = 'chartreuse') and
        (i_units = 'Gross' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'blanched' or i_color = 'puff') and 
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'slate') and
        (i_units = 'Tsp' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'brown') and
        (i_units = 'Dram' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'rosy') and
        (i_units = 'Box' or i_units = 'Carton') and
        (i_size = 'petite' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
