
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_net_profit) > 0
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_profit,
        ROW_NUMBER() OVER (ORDER BY SUM(cs_net_profit) DESC) AS rank
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_net_profit) > 0
),
sales_summary AS (
    SELECT 
        s.ws_item_sk,
        s.total_quantity,
        s.total_profit,
        d.d_year,
        d.d_month_seq
    FROM 
        sales_cte s
    INNER JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date <= CURRENT_DATE)
)
SELECT 
    st.s_store_id,
    ca.ca_city,
    SUM(ss.total_quantity) AS total_quantity_sold,
    AVG(ss.total_profit) AS average_profit_per_item,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers
FROM 
    sales_summary ss
LEFT JOIN 
    store_sales st ON st.ss_item_sk = ss.ws_item_sk
LEFT JOIN 
    customer c ON c.c_customer_sk = st.ss_customer_sk
LEFT JOIN 
    customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
WHERE 
    ca.ca_state = 'CA' 
AND 
    ss.total_profit IS NOT NULL
GROUP BY 
    st.s_store_id, ca.ca_city
HAVING 
    SUM(ss.total_quantity) > 100
ORDER BY 
    average_profit_per_item DESC
LIMIT 10;
