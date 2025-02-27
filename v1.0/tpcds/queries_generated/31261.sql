
WITH RECURSIVE sales_rank AS (
    SELECT 
        ws_item_sk, 
        ROW_NUMBER() OVER (PARTITION BY ws_web_site_sk ORDER BY ws_ext_sales_price DESC) AS rank_sales,
        SUM(ws_ext_sales_price) OVER (PARTITION BY ws_item_sk) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
), 
customer_info AS (
    SELECT 
        c.c_customer_id, 
        cd.cd_gender, 
        cd.cd_marital_status, 
        cd.cd_purchase_estimate, 
        c.c_first_name || ' ' || c.c_last_name AS full_name, 
        ca.ca_city, 
        ca.ca_state
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        cd.cd_purchase_estimate > 10000
), 
sales_summary AS (
    SELECT 
        ci.full_name,
        ci.ca_city,
        ci.ca_state,
        sr.rank_sales,
        sr.total_sales
    FROM 
        sales_rank sr
    JOIN 
        web_sales ws ON sr.ws_item_sk = ws.ws_item_sk
    JOIN 
        customer_info ci ON ws.ws_bill_customer_sk = ci.c_customer_id
    WHERE 
        sr.rank_sales <= 5
)
SELECT 
    ss.full_name,
    ss.ca_city,
    ss.ca_state,
    ss.total_sales,
    CASE 
        WHEN ss.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status,
    (SELECT COUNT(*) 
     FROM store_sales s
     WHERE s.ss_item_sk = sr.ws_item_sk 
     AND s.ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
     AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)) AS store_sales_count
FROM 
    sales_summary ss
JOIN 
    customer_info ci ON ss.full_name = ci.full_name
WHERE 
    ss.ca_state IS NOT NULL
ORDER BY 
    ss.total_sales DESC;
