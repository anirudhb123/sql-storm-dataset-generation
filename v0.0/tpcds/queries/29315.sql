
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 785 and 785+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'azure' or i_color = 'sky') and 
        (i_units = 'Lb' or i_units = 'Tsp') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'khaki' or i_color = 'rose') and
        (i_units = 'Case' or i_units = 'Pound') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'almond' or i_color = 'lawn') and
        (i_units = 'Cup' or i_units = 'Gram') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'navy' or i_color = 'dim') and
        (i_units = 'Oz' or i_units = 'Ton') and
        (i_size = 'large' or i_size = 'extra large')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'antique' or i_color = 'frosted') and 
        (i_units = 'Carton' or i_units = 'Dozen') and
        (i_size = 'large' or i_size = 'extra large')
        ) or
        (i_category = 'Women' and
        (i_color = 'honeydew' or i_color = 'wheat') and
        (i_units = 'N/A' or i_units = 'Dram') and
        (i_size = 'N/A' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chartreuse' or i_color = 'sandy') and
        (i_units = 'Box' or i_units = 'Each') and
        (i_size = 'small' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'steel' or i_color = 'lemon') and
        (i_units = 'Pallet' or i_units = 'Tbl') and
        (i_size = 'large' or i_size = 'extra large')
        )))) > 0
 order by i_product_name
 limit 100;
