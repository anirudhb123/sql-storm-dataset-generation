
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 667 and 667+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'thistle' or i_color = 'wheat') and 
        (i_units = 'N/A' or i_units = 'Unknown') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'sandy' or i_color = 'lime') and
        (i_units = 'Ounce' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'honeydew' or i_color = 'peru') and
        (i_units = 'Ton' or i_units = 'Bunch') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'tomato' or i_color = 'yellow') and
        (i_units = 'Box' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'economy')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'grey' or i_color = 'plum') and 
        (i_units = 'Gross' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Women' and
        (i_color = 'puff' or i_color = 'beige') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'ivory' or i_color = 'medium') and
        (i_units = 'Each' or i_units = 'Cup') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'white') and
        (i_units = 'Tsp' or i_units = 'Carton') and
        (i_size = 'small' or i_size = 'economy')
        )))) > 0
 order by i_product_name
 limit 100;
