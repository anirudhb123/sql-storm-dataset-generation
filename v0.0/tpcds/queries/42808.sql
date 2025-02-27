
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 756 and 756+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'moccasin' or i_color = 'ghost') and 
        (i_units = 'Carton' or i_units = 'Each') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lace' or i_color = 'coral') and
        (i_units = 'Pallet' or i_units = 'Lb') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'blanched') and
        (i_units = 'Gram' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'dark') and
        (i_units = 'Box' or i_units = 'Gross') and
        (i_size = 'medium' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'cyan' or i_color = 'cornflower') and 
        (i_units = 'Dram' or i_units = 'Cup') and
        (i_size = 'medium' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'blue' or i_color = 'cornsilk') and
        (i_units = 'Unknown' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'smoke' or i_color = 'saddle') and
        (i_units = 'Oz' or i_units = 'Bunch') and
        (i_size = 'large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'pale' or i_color = 'papaya') and
        (i_units = 'Case' or i_units = 'Tsp') and
        (i_size = 'medium' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
