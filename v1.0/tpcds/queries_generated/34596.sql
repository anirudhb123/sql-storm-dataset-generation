
WITH Recursive_CTE AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state

    UNION ALL

    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        Recursive_CTE r ON ca.ca_city = r.ca_city AND ca.ca_state = r.ca_state
    WHERE 
        ca.ca_address_sk != r.ca_address_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    SUM(a.customer_count) AS total_customers,
    MAX(a.customer_count) AS max_customers_at_address,
    MIN(a.customer_count) AS min_customers_at_address
FROM 
    Recursive_CTE a
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    total_customers > 50
ORDER BY 
    total_customers DESC;

WITH Ranking AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
Top_Sales AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales
    FROM 
        Ranking r
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    ts.total_sales
FROM 
    item i
JOIN 
    Top_Sales ts ON i.i_item_sk = ts.ws_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    ts.total_sales DESC;

SELECT 
    p.p_promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales
FROM 
    web_sales ws
JOIN 
    promotion p ON ws.ws_promo_sk = p.p_promo_sk
WHERE 
    p.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    AND p.p_end_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    p.p_promo_name
HAVING 
    SUM(ws.ws_ext_sales_price) > 10000
ORDER BY 
    total_sales DESC;

SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    ca.ca_city,
    COUNT(r.sr_item_sk) AS total_returns
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    store_returns r ON c.c_customer_sk = r.sr_customer_sk
WHERE 
    ca.ca_state IS NOT NULL
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city
HAVING 
    COUNT(r.sr_item_sk) > 5
ORDER BY 
    total_returns DESC;
