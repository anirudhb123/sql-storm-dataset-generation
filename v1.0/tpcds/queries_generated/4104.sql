
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price BETWEEN 10.00 AND 500.00
    GROUP BY 
        ws.web_site_sk, ws.ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_id,
        d.d_year,
        cd.cd_marital_status,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND d.d_year >= 2020
    GROUP BY 
        c.c_customer_id, d.d_year, cd.cd_marital_status
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    SUM(ss.ss_ext_sales_price) AS store_sales_total,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
    AVG(ws.ws_net_profit) AS avg_web_net_profit
FROM 
    customer_address ca
LEFT JOIN 
    store s ON ca.ca_address_sk = s.s_store_sk
LEFT JOIN 
    store_sales ss ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN 
    web_sales ws ON ws.ws_item_sk IN (SELECT ws_item_sk FROM ranked_sales WHERE sales_rank = 1)
WHERE 
    ca.ca_country = 'USA'
    AND (s.s_closed_date_sk IS NULL OR s.s_closed_date_sk > CURRENT_DATE)
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    SUM(ss.ss_ext_sales_price) > (SELECT AVG(total_sales) FROM ranked_sales)
ORDER BY 
    store_sales_total DESC;
