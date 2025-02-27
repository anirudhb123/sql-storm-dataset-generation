
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
HighValueItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.rank = 1
)

SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    a.ca_city,
    SUM(sws.net_paid) AS total_net_paid,
    COUNT(DISTINCT sws.ws_order_number) AS order_count,
    AVG(sws.ws_net_paid_inc_ship_tax) AS avg_order_value,
    CASE 
        WHEN AVG(sws.ws_net_paid_inc_tax) IS NULL THEN 'No Sales'
        WHEN AVG(sws.ws_net_paid_inc_tax) < 50 THEN 'Low Spender'
        WHEN AVG(sws.ws_net_paid_inc_tax) BETWEEN 50 AND 100 THEN 'Medium Spender'
        ELSE 'High Spender'
    END AS spending_category
FROM 
    customer c
JOIN 
    customer_address a ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    web_sales sws ON c.c_customer_sk = sws.ws_bill_customer_sk
LEFT JOIN 
    HighValueItems hvi ON sws.ws_item_sk = hvi.ws_item_sk
WHERE 
    a.ca_state IS NOT NULL
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city
HAVING 
    SUM(sws.net_paid) > 1000 OR COUNT(DISTINCT sws.ws_order_number) > 5
ORDER BY 
    total_net_paid DESC;
