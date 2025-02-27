
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 903 and 903+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'honeydew' or i_color = 'moccasin') and 
        (i_units = 'Lb' or i_units = 'Gross') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'goldenrod' or i_color = 'lawn') and
        (i_units = 'N/A' or i_units = 'Pallet') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'orchid' or i_color = 'burlywood') and
        (i_units = 'Unknown' or i_units = 'Cup') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'firebrick' or i_color = 'brown') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'extra large' or i_size = 'medium')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'ivory' or i_color = 'lemon') and 
        (i_units = 'Ton' or i_units = 'Oz') and
        (i_size = 'extra large' or i_size = 'medium')
        ) or
        (i_category = 'Women' and
        (i_color = 'grey' or i_color = 'khaki') and
        (i_units = 'Carton' or i_units = 'Tbl') and
        (i_size = 'petite' or i_size = 'economy')
        ) or
        (i_category = 'Men' and
        (i_color = 'chocolate' or i_color = 'almond') and
        (i_units = 'Case' or i_units = 'Dozen') and
        (i_size = 'small' or i_size = 'N/A')
        ) or
        (i_category = 'Men' and
        (i_color = 'green' or i_color = 'blanched') and
        (i_units = 'Dram' or i_units = 'Bundle') and
        (i_size = 'extra large' or i_size = 'medium')
        )))) > 0
 order by i_product_name
 limit 100;
