
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ss_item_sk,
        SUM(ss_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY ss_sold_date_sk DESC) AS rn
    FROM store_sales
    WHERE ss_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    GROUP BY ss_item_sk
),
Customer_Agg AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        SUM(ws.net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_last_name
),
Tabulated AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(da.d_year) AS last_purchase_year,
        COALESCE(SUM(ca.ca_gmt_offset), 0) AS total_offset
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN date_dim da ON da.d_date_sk IN (
        SELECT DISTINCT ws.ws_sold_date_sk 
        FROM web_sales ws
        WHERE ws.ws_bill_customer_sk IS NOT NULL
    )
    GROUP BY ca.ca_address_sk, ca.ca_city
),
Ranked_Sales AS (
    SELECT 
        sa.total_profit,
        ca.ca_city,
        RANK() OVER (ORDER BY sa.total_profit DESC) AS profit_rank
    FROM Sales_CTE sa
    JOIN customer c ON c.c_customer_sk = sa.ss_item_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    ta.ca_city,
    ta.customer_count,
    ta.last_purchase_year,
    ra.total_profit,
    ra.profit_rank,
    ca.total_net_profit,
    ca.total_orders,
    ca.unique_items
FROM Tabulated ta
JOIN Ranked_Sales ra ON ta.ca_city = ra.ca_city
JOIN Customer_Agg ca ON ta.customer_count > 10 AND ca.total_net_profit > 1000
WHERE ra.profit_rank <= 10
ORDER BY ta.customer_count DESC, ra.total_profit ASC;
