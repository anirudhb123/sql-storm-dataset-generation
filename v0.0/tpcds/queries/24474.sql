
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 839 and 839+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'magenta' or i_color = 'chiffon') and 
        (i_units = 'Carton' or i_units = 'Bunch') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'pink' or i_color = 'indian') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'puff' or i_color = 'sienna') and
        (i_units = 'Oz' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'papaya') and
        (i_units = 'Tsp' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'burnished' or i_color = 'azure') and 
        (i_units = 'Ounce' or i_units = 'Case') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'burlywood' or i_color = 'blush') and
        (i_units = 'Gross' or i_units = 'Lb') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'frosted') and
        (i_units = 'Gram' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'blanched' or i_color = 'forest') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
