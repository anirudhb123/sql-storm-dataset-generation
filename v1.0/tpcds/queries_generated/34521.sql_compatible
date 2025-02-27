
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk, 
        ws_item_sk, 
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS sales_rank
    FROM web_sales
    GROUP BY ws_sold_date_sk, ws_item_sk
    HAVING SUM(ws_sales_price) > 0
), 
GroupedSales AS (
    SELECT 
        s_item_sk,
        SUM(total_sales) AS aggregated_sales,
        AVG(total_orders) AS avg_orders
    FROM SalesCTE
    GROUP BY s_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        COALESCE(gs.aggregated_sales, 0) AS total_sales,
        gs.avg_orders
    FROM item
    LEFT JOIN GroupedSales gs ON item.i_item_sk = gs.s_item_sk
    WHERE item.i_current_price IS NOT NULL
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        SUM(ss.net_paid_inc_tax) AS total_spent
    FROM customer c
    JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE ss.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY c.c_customer_sk
    HAVING SUM(ss.net_paid_inc_tax) > 1000
)
SELECT 
    ti.i_item_id,
    COUNT(DISTINCT hvc.c_customer_sk) AS high_value_customer_count,
    ti.total_sales,
    ti.avg_orders
FROM TopItems ti
INNER JOIN HighValueCustomers hvc ON ti.total_sales > 0 AND hvc.total_spent > 1000
GROUP BY ti.i_item_id, ti.total_sales, ti.avg_orders
ORDER BY ti.total_sales DESC
LIMIT 10;
