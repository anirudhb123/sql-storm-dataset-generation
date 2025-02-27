
WITH aggregated_sales AS (
    SELECT 
        ws_cdemo_sk,
        SUM(ws_net_paid) AS total_web_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        MAX(ws_sold_date_sk) AS last_purchase_date
    FROM 
        web_sales 
    WHERE 
        ws_ship_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_cdemo_sk
), customer_details AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
), sales_summary AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT asales.ws_cdemo_sk) AS customer_count,
        SUM(asales.total_web_sales) AS total_sales,
        AVG(asales.total_web_sales) AS avg_sales_per_customer,
        MAX(asales.last_purchase_date) AS latest_purchase
    FROM 
        aggregated_sales asales
    JOIN 
        customer_details cd ON asales.ws_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
)
SELECT 
    sd.cd_gender,
    sd.cd_marital_status,
    sd.cd_education_status,
    sd.customer_count,
    sd.total_sales,
    sd.avg_sales_per_customer,
    sd.latest_purchase
FROM 
    sales_summary sd
WHERE 
    sd.customer_count > 100
ORDER BY 
    total_sales DESC;
