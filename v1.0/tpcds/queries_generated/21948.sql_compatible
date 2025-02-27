
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452011 AND 2452018
    GROUP BY ws_item_sk
),
TopStores AS (
    SELECT 
        ss_store_sk, 
        AVG(ss_net_profit) AS avg_net_profit
    FROM store_sales
    GROUP BY ss_store_sk
    HAVING AVG(ss_net_profit) > (
        SELECT AVG(ss_net_profit) FROM store_sales
    )
),
CustomerActivity AS (
    SELECT 
        c_customer_sk, 
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COALESCE(SUM(ws_net_paid_inc_tax), 0) AS total_spent
    FROM customer
    LEFT JOIN web_sales ON c_customer_sk = ws_bill_customer_sk
    GROUP BY c_customer_sk
)
SELECT 
    ca.c_first_name,
    ca.c_last_name,
    ca.c_birth_month,
    COALESCE(RS.total_quantity, 0) AS total_quantity_sold,
    COALESCE(RS.total_sales, 0) AS total_sales_value,
    CA.total_orders,
    CA.total_spent,
    TS.ss_store_sk,
    TS.avg_net_profit
FROM customer AS ca
LEFT JOIN CustomerActivity AS CA ON ca.c_customer_sk = CA.c_customer_sk
LEFT JOIN RankedSales AS RS ON RS.ws_item_sk IN (
    SELECT ws_item_sk FROM RankedSales WHERE sales_rank <= 10
)
JOIN TopStores AS TS ON TS.ss_store_sk = (
    SELECT ss_store_sk FROM store_sales WHERE ss_ticket_number IS NOT NULL
    ORDER BY ss_net_profit DESC
    LIMIT 1
)
WHERE (ca.c_birth_month BETWEEN 1 AND 6 OR ca.c_birth_month IS NULL)
AND (TS.avg_net_profit IS NOT NULL)
ORDER BY total_sales_value DESC, total_quantity_sold DESC;
