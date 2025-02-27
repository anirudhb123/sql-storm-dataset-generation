
WITH RankedSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_order_number,
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1 AND 1000
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_order_number
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        COUNT(cd.cd_demo_sk) AS demographic_count
    FROM 
        customer_demographics cd
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    CASE 
        WHEN cd.demographic_count > 10 THEN 'Active'
        ELSE 'Inactive' 
    END AS customer_status,
    COUNT(DISTINCT r.ws_order_number) AS total_orders,
    SUM(COALESCE(ws.ws_ext_discount_amt, 0)) AS total_discount,
    STRING_AGG(DISTINCT cd.cd_gender, ', ') AS gender_distribution
FROM 
    RankedSales r
LEFT JOIN 
    CustomerDemographics cd ON r.c_customer_sk = cd.cd_demo_sk
LEFT JOIN 
    web_sales ws ON r.ws_order_number = ws.ws_order_number
WHERE 
    r.sales_rank <= 5
GROUP BY 
    r.c_first_name, r.c_last_name, r.total_sales, cd.demographic_count
HAVING 
    SUM(ws.ws_sales_price) > 1000
ORDER BY 
    r.total_sales DESC;
