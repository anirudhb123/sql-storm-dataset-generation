
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_net_profit,
        1 AS level
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)

    UNION ALL

    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_profit,
        cte.level + 1
    FROM web_sales ws
    JOIN SalesCTE cte ON ws.ws_item_sk = cte.ws_item_sk AND ws.ws_order_number < cte.ws_order_number
    WHERE cte.level < 10
),
AggregatedSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_profit) AS total_net_profit,
        COUNT(*) AS sales_count
    FROM web_sales s
    GROUP BY s.ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS profit
    FROM customer c
    LEFT JOIN customer_demographics d ON c.c_current_cdemo_sk = d.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, d.cd_gender
)
SELECT 
    ca.ca_address_id,
    cus.c_first_name,
    cus.c_last_name,
    COALESCE(s.total_quantity, 0) AS total_sales_quantity,
    COALESCE(s.total_net_profit, 0) AS total_sales_profit,
    COALESCE(c.total_orders, 0) AS total_orders,
    cus.cd_gender
FROM customer_address ca
LEFT JOIN customer cus ON ca.ca_address_sk = cus.c_current_addr_sk 
LEFT JOIN AggregatedSales s ON cus.c_customer_sk = s.ws_item_sk
LEFT JOIN CustomerData c ON cus.c_customer_sk = c.c_customer_sk
WHERE (cus.c_birth_year IS NULL OR cus.c_birth_year > 1980)
AND (s.total_net_profit > 0 OR s.total_quantity IS NULL)
ORDER BY total_sales_profit DESC, ca.ca_address_id
LIMIT 100;
