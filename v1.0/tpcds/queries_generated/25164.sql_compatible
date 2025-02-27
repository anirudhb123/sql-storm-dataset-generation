
WITH demographics AS (
    SELECT 
        cd_gender,
        COUNT(*) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd_dep_count) AS total_dependencies,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
    FROM 
        customer_demographics
    GROUP BY 
        cd_gender
),
combined_data AS (
    SELECT 
        c.c_customer_id,
        ca.ca_city,
        cd.cd_gender,
        ws.ws_sales_price,
        ws.ws_net_profit
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ca.ca_city IS NOT NULL
    AND 
        ws.ws_sales_price > 50
),
avg_sales AS (
    SELECT 
        ca.ca_city,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(*) AS number_of_sales
    FROM 
        combined_data
    GROUP BY 
        ca.ca_city
)
SELECT 
    d.cd_gender,
    d.customer_count,
    d.avg_purchase_estimate,
    d.total_dependencies,
    d.married_count,
    d.single_count,
    a.ca_city,
    a.avg_sales_price,
    a.number_of_sales
FROM 
    demographics d
JOIN 
    avg_sales a ON a.number_of_sales > 5
ORDER BY 
    d.cd_gender, a.avg_sales_price DESC;
