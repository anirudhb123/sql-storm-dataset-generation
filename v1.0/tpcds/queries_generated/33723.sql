
WITH RECURSIVE SalesCTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY ws_item_sk

    UNION ALL

    SELECT
        i.i_item_sk,
        SUM(cs_sales_price) AS total_sales,
        COUNT(cs_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(cs_sales_price) DESC) AS rank
    FROM item i
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    WHERE cs.cs_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY i.i_item_sk
),
AggregateSales AS (
    SELECT
        item_sk,
        SUM(total_sales) AS cumulative_sales,
        SUM(order_count) AS cumulative_orders
    FROM (
        SELECT
            ws_item_sk AS item_sk,
            total_sales,
            order_count
        FROM SalesCTE
        WHERE rank = 1
        
        UNION ALL
        
        SELECT
            cs_item_sk AS item_sk,
            total_sales,
            order_count
        FROM SalesCTE
        WHERE rank = 1
    ) AS CombinedSales
    GROUP BY item_sk
)
SELECT
    ca.ca_city,
    SUM(as.cumulative_sales) AS total_revenue,
    COUNT(DISTINCT as.cumulative_orders) AS unique_orders,
    (SELECT COUNT(DISTINCT c_customer_sk)
     FROM customer c
     WHERE c.c_current_addr_sk IS NOT NULL) AS total_customers
FROM customer_address ca
INNER JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN AggregateSales as ON as.item_sk IN (
    SELECT DISTINCT
        ws_item_sk
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 1 AND 1000
)
GROUP BY ca.ca_city
HAVING total_revenue IS NOT NULL AND total_revenue > 50000
ORDER BY total_revenue DESC;
