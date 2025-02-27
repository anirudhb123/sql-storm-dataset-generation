
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
), 
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd_cd_demo_sk,
        cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd_credit_rating ORDER BY cd_purchase_estimate DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd_purchase_estimate IS NOT NULL AND 
        cd_credit_rating IS NOT NULL
    HAVING 
        cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
)
SELECT 
    aa.ca_city,
    COUNT(DISTINCT hc.c_customer_sk) AS high_value_customer_count,
    SUM(ss.total_sales) AS total_sales_value
FROM 
    customer_address aa
LEFT JOIN 
    customer c ON aa.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    high_value_customers hc ON c.c_customer_sk = hc.c_customer_sk
LEFT JOIN 
    sales_summary ss ON ss.ws_item_sk IN (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 1)
            AND (SELECT d_date_sk FROM date_dim WHERE d_year = 2023 AND d_moy = 12)
    )
GROUP BY 
    aa.ca_city
HAVING 
    COUNT(DISTINCT hc.c_customer_sk) > 5 OR total_sales_value IS NOT NULL
ORDER BY 
    total_sales_value DESC
LIMIT 100;
