
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 699 and 699+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'pale' or i_color = 'light') and 
        (i_units = 'Pound' or i_units = 'Cup') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'steel' or i_color = 'chiffon') and
        (i_units = 'Gross' or i_units = 'Bunch') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'gainsboro' or i_color = 'chartreuse') and
        (i_units = 'Bundle' or i_units = 'Pallet') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'hot' or i_color = 'chocolate') and
        (i_units = 'Lb' or i_units = 'Gram') and
        (i_size = 'extra large' or i_size = 'petite')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'seashell' or i_color = 'blue') and 
        (i_units = 'Tbl' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Women' and
        (i_color = 'smoke' or i_color = 'navy') and
        (i_units = 'Case' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'coral') and
        (i_units = 'Dram' or i_units = 'Ounce') and
        (i_size = 'N/A' or i_size = 'medium')
        ) or
        (i_category = 'Men' and
        (i_color = 'metallic' or i_color = 'violet') and
        (i_units = 'Tsp' or i_units = 'Unknown') and
        (i_size = 'extra large' or i_size = 'petite')
        )))) > 0
 order by i_product_name
 limit 100;
