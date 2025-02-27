
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.shipping_date,
        ws.net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_paid DESC) AS sales_rank,
        DATE(dd.d_date) AS sales_date,
        DENSE_RANK() OVER (ORDER BY DATE(dd.d_date)) AS date_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_amount
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_purchase_estimate > 1000
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    ws.web_site_sk,
    COUNT(DISTINCT c.c_customer_id) AS unique_customers,
    SUM(ws.ws_net_paid) AS total_sales,
    AVG(ws.ws_net_paid) AS avg_order_amount,
    COUNT(CASE WHEN ws.ws_net_paid IS NULL THEN 1 END) AS null_sales_count,
    MAX(sales_rank) AS max_sales_rank,
    MIN(sales_rank) AS min_sales_rank,
    STRING_AGG(DISTINCT cd.cd_gender) AS customer_genders
FROM 
    web_sales AS ws
LEFT JOIN 
    CustomerStats AS stats ON ws.ws_bill_customer_sk = stats.c_customer_sk
JOIN 
    RankedSales AS r ON ws.web_site_sk = r.web_site_sk
GROUP BY 
    ws.web_site_sk
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 5
ORDER BY 
    total_sales DESC
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
