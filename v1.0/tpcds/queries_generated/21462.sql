
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
high_value_sales AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price
    FROM 
        ranked_sales rs
    WHERE 
        rs.sales_rank <= 10
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        ca.ca_country,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
sales_summary AS (
    SELECT 
        ci.c_customer_sk,
        ci.ca_country,
        SUM(hvs.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT hvs.ws_order_number) AS order_count
    FROM 
        customer_info ci
    JOIN 
        high_value_sales hvs ON ci.c_current_addr_sk IN (
            SELECT sr_addr_sk 
            FROM store_returns 
            WHERE sr_item_sk = hvs.ws_item_sk
            GROUP BY sr_addr_sk
            HAVING COUNT(*) > 1
        )
    GROUP BY 
        ci.c_customer_sk, ci.ca_country
)
SELECT 
    ss.c_customer_sk,
    ss.ca_country,
    ss.total_sales,
    ss.order_count,
    COALESCE((SELECT COUNT(*) 
               FROM catalog_sales cs 
               WHERE cs.cs_ship_mode_sk IN (
                   SELECT sm.sm_ship_mode_sk 
                   FROM ship_mode sm 
                   WHERE sm.sm_type LIKE 'Air%'
               ) AND cs.cs_item_sk = hvs.ws_item_sk), 0) AS air_shipping_count,
    (SELECT AVG(cd.cd_purchase_estimate) 
     FROM customer_demographics cd 
     WHERE cd.cd_demo_sk IN (SELECT ci.c_current_cdemo_sk FROM customer_info ci WHERE ci.ca_country IS NULL)) AS avg_purchase_estimate_null_country
FROM 
    sales_summary ss
LEFT JOIN 
    high_value_sales hvs ON ss.c_customer_sk IN (
        SELECT sr_customer_sk FROM store_returns
    )
ORDER BY 
    ss.total_sales DESC, 
    ss.ca_country IS NULL, 
    ss.order_count DESC
LIMIT 50;
