
WITH RECURSIVE Sales_CTE AS (
    SELECT cs_order_number, 
           SUM(cs_net_profit) AS total_profit,
           COUNT(cs_order_number) AS order_count,
           cs_item_sk
    FROM catalog_sales
    GROUP BY cs_order_number, cs_item_sk
), 
Profit_Per_Item AS (
    SELECT cs_item_sk, 
           AVG(total_profit) AS avg_profit, 
           SUM(order_count) AS total_orders
    FROM Sales_CTE
    GROUP BY cs_item_sk
), 
Top_Products AS (
    SELECT i_product_name, 
           p_promo_name,
           pp.avg_profit,
           pp.total_orders,
           RANK() OVER (ORDER BY pp.avg_profit DESC) AS profit_rank
    FROM item
    JOIN Profit_Per_Item pp ON i_item_sk = pp.cs_item_sk
    LEFT JOIN promotion p ON p.p_item_sk = pp.cs_item_sk
    WHERE pp.total_orders > 5
    AND p.p_discount_active = 'Y'
)
SELECT tp.i_product_name, 
       tp.avg_profit, 
       tp.total_orders, 
       CASE 
           WHEN tp.profit_rank <= 10 THEN 'Top Performer'
           ELSE 'Average Performer'
       END AS performance_category
FROM Top_Products tp
WHERE EXISTS (
    SELECT 1 
    FROM store_sales ss
    WHERE ss.ss_item_sk = tp.cs_item_sk 
    AND ss.ss_sold_date_sk > (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_current_year = 'Y'
    )
)
ORDER BY tp.avg_profit DESC;
