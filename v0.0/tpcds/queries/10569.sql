
-- end query 61 in stream 0 using template query42.tpl
-- start query 62 in stream 0 using template query41.tpl
select  distinct(i_product_name)
 from item i1
 where i_manufact_id between 741 and 741+40 
   and (select count(*) as item_cnt
        from item
        where (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'chartreuse' or i_color = 'grey') and 
        (i_units = 'Dozen' or i_units = 'Carton') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'snow' or i_color = 'violet') and
        (i_units = 'Pallet' or i_units = 'Gross') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'magenta' or i_color = 'honeydew') and
        (i_units = 'Tsp' or i_units = 'Pound') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'plum' or i_color = 'light') and
        (i_units = 'Cup' or i_units = 'Tbl') and
        (i_size = 'extra large' or i_size = 'N/A')
        ))) or
       (i_manufact = i1.i_manufact and
        ((i_category = 'Women' and 
        (i_color = 'slate' or i_color = 'gainsboro') and 
        (i_units = 'Unknown' or i_units = 'N/A') and
        (i_size = 'extra large' or i_size = 'N/A')
        ) or
        (i_category = 'Women' and
        (i_color = 'lime' or i_color = 'green') and
        (i_units = 'Bundle' or i_units = 'Ounce') and
        (i_size = 'economy' or i_size = 'small')
        ) or
        (i_category = 'Men' and
        (i_color = 'dodger' or i_color = 'orange') and
        (i_units = 'Oz' or i_units = 'Bunch') and
        (i_size = 'medium' or i_size = 'petite')
        ) or
        (i_category = 'Men' and
        (i_color = 'lavender' or i_color = 'blush') and
        (i_units = 'Lb' or i_units = 'Ton') and
        (i_size = 'extra large' or i_size = 'N/A')
        )))) > 0
 order by i_product_name
 limit 100;
