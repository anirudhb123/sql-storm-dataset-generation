
WITH RECURSIVE sales_summary AS (
    SELECT
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ws_net_profit,
        ws_sold_date_sk,
        1 AS level
    FROM
        web_sales
    WHERE
        ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
    
    UNION ALL
    
    SELECT
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ws_net_profit,
        ws_sold_date_sk,
        level + 1
    FROM
        web_sales
    WHERE
        ws_sold_date_sk < (
            SELECT MAX(ws_sold_date_sk) FROM web_sales
        ) AND level < 10
        AND ws_quantity > (SELECT AVG(ws_quantity) FROM web_sales)
)

SELECT
    c.c_customer_id,
    ca.ca_city,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    COUNT(DISTINCT s.ss_ticket_number) AS total_sales,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    (SELECT COUNT(*) FROM store_sales ss WHERE ss.ss_sold_date_sk BETWEEN (CURRENT_DATE - INTERVAL '30 days') AND CURRENT_DATE) AS recent_store_sales,
    CASE
        WHEN SUM(ws.ws_net_profit) IS NULL THEN 'No Profit'
        ELSE 'Profit Achieved'
    END AS profit_status
FROM
    customer c
LEFT JOIN
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
FULL OUTER JOIN
    store_sales s ON s.ss_customer_sk = c.c_customer_sk
LEFT JOIN
    web_returns wr ON wr.wr_returning_customer_sk = c.c_customer_sk
WHERE
    ca.ca_state IN ('CA', 'TX')
    AND c.c_birth_year BETWEEN 1980 AND 2000
GROUP BY
    c.c_customer_id,
    ca.ca_city
HAVING
    SUM(ws.ws_quantity) > 100
ORDER BY
    total_net_paid DESC
LIMIT 100;
