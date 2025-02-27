
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 826 and 826+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'orchid' or i_color = 'light') and 
        (i_units = 'Unknown' or i_units = 'Pound') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'brown' or i_color = 'cyan') and
        (i_units = 'Gross' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'blue' or i_color = 'cornflower') and
        (i_units = 'Box' or i_units = 'Dozen') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'forest' or i_color = 'coral') and
        (i_units = 'Bundle' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chiffon' or i_color = 'misty') and 
        (i_units = 'Cup' or i_units = 'Oz') and
        (i_size = 'small' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'violet' or i_color = 'chocolate') and
        (i_units = 'Bunch' or i_units = 'Pallet') and
        (i_size = 'extra large' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'dim' or i_color = 'beige') and
        (i_units = 'Ounce' or i_units = 'Tsp') and
        (i_size = 'economy' or i_size = 'large')
        ) or
        (i_category = 'Men' and
        (i_color = 'azure' or i_color = 'ghost') and
        (i_units = 'Case' or i_units = 'Tbl') and
        (i_size = 'small' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
