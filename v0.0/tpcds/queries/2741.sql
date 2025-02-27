
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 889 and 889+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'lace' or i_color = 'rosy') and 
        (i_units = 'Case' or i_units = 'Tsp') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'cornflower' or i_color = 'rose') and
        (i_units = 'Gross' or i_units = 'Dozen') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'black' or i_color = 'frosted') and
        (i_units = 'Ounce' or i_units = 'Bunch') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'grey' or i_color = 'metallic') and
        (i_units = 'Ton' or i_units = 'Dram') and
        (i_size = 'petite' or i_size = 'large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'puff' or i_color = 'honeydew') and 
        (i_units = 'Pallet' or i_units = 'Unknown') and
        (i_size = 'petite' or i_size = 'large')
        ) or
        (i_category = 'Women' and
        (i_color = 'red' or i_color = 'forest') and
        (i_units = 'Lb' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'cyan' or i_color = 'firebrick') and
        (i_units = 'Tbl' or i_units = 'Oz') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'medium' or i_color = 'ghost') and
        (i_units = 'Carton' or i_units = 'Each') and
        (i_size = 'petite' or i_size = 'large')
        )))) > 0
 order by i_product_name
 limit 100;
