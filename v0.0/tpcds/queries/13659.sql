
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 828 and 828+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'medium' or i_color = 'smoke') and 
        (i_units = 'Cup' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'dodger' or i_color = 'navy') and
        (i_units = 'Bundle' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'burnished') and
        (i_units = 'Oz' or i_units = 'Tsp') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'forest') and
        (i_units = 'Dozen' or i_units = 'Dram') and
        (i_size = 'extra large' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'white' or i_color = 'blanched') and 
        (i_units = 'Pallet' or i_units = 'Box') and
        (i_size = 'extra large' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'slate') and
        (i_units = 'Each' or i_units = 'N/A') and
        (i_size = 'petite' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'wheat' or i_color = 'cream') and
        (i_units = 'Ounce' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'bisque' or i_color = 'firebrick') and
        (i_units = 'Tbl' or i_units = 'Lb') and
        (i_size = 'extra large' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
