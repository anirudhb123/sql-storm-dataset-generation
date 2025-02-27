
WITH RankedSales AS (
    SELECT ws.ws_item_sk,
           ws.ws_order_number,
           ws.ws_sales_price,
           ws.ws_net_profit,
           DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
           ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS recent_sales
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim) - 30 AND (SELECT MAX(d_date_sk) FROM date_dim)
),
ItemSales AS (
    SELECT ir.i_item_sk,
           ir.i_product_name,
           COALESCE(SUM(rs.ws_net_profit), 0) AS total_net_profit,
           COUNT(rs.ws_order_number) AS total_orders
    FROM item ir
    LEFT JOIN RankedSales rs ON ir.i_item_sk = rs.ws_item_sk
    GROUP BY ir.i_item_sk, ir.i_product_name
),
ProfitableItems AS (
    SELECT is.i_item_sk,
           is.i_product_name,
           is.total_net_profit,
           is.total_orders,
           CASE 
               WHEN is.total_net_profit = 0 THEN 'No Profit'
               WHEN is.total_net_profit < 100 THEN 'Low Profit'
               ELSE 'High Profit' 
           END AS profit_category
    FROM ItemSales is
    WHERE is.total_net_profit IS NOT NULL
),
TopItems AS (
    SELECT *,
           RANK() OVER (ORDER BY total_net_profit DESC) AS overall_rank
    FROM ProfitableItems
)
SELECT ti.i_product_name,
       ti.total_net_profit,
       ti.total_orders,
       ti.profit_category,
       (SELECT COUNT(DISTINCT c.c_customer_sk) FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        JOIN TopItems ti2 ON ws.ws_item_sk = ti2.i_item_sk
        WHERE ti2.overall_rank <= 10) AS unique_customers_count
FROM TopItems ti
WHERE ti.overall_rank <= 10
UNION ALL
SELECT 'Overall Total' AS i_product_name,
       SUM(total_net_profit) AS total_net_profit,
       NULL AS total_orders,
       NULL AS profit_category
FROM ProfitableItems
WHERE total_net_profit IS NOT NULL
ORDER BY total_net_profit DESC;
