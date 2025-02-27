
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sales_price,
        ws.ws_quantity,
        cd.cd_gender,
        cd.cd_marital_status,
        dd.d_year,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
)
SELECT 
    web_site_id,
    SUM(ws_sales_price * ws_quantity) AS total_sales,
    COUNT(DISTINCT web_site_id) AS number_of_transactions,
    COUNT(CASE WHEN cd_gender = 'F' THEN 1 END) AS female_transactions,
    COUNT(CASE WHEN cd_gender = 'M' THEN 1 END) AS male_transactions
FROM 
    RankedSales
WHERE 
    sales_rank <= 10
GROUP BY 
    web_site_id
ORDER BY 
    total_sales DESC
LIMIT 10;
