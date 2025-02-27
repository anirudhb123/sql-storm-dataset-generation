
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 942 and 942+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'snow' or i_color = 'dark') and 
        (i_units = 'Box' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'slate' or i_color = 'maroon') and
        (i_units = 'Oz' or i_units = 'Case') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'firebrick') and
        (i_units = 'Gross' or i_units = 'Bundle') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'chiffon' or i_color = 'papaya') and
        (i_units = 'Gram' or i_units = 'Lb') and
        (i_size = 'small' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'goldenrod' or i_color = 'cornflower') and 
        (i_units = 'Dozen' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'lace') and
        (i_units = 'N/A' or i_units = 'Tsp') and
        (i_size = 'N/A' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'burnished' or i_color = 'spring') and
        (i_units = 'Tbl' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'azure') and
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
