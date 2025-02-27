
WITH RECURSIVE SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_sales
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.ws_sold_date_sk
),
FilteredSales AS (
    SELECT 
        web_site_id,
        total_sales,
        total_orders,
        rank_sales
    FROM 
        SalesData
    WHERE 
        rank_sales <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
    HAVING 
        SUM(ws.ws_net_profit) IS NOT NULL
),
FinalSales AS (
    SELECT 
        fs.web_site_id,
        ci.order_count,
        ci.total_profit,
        fs.total_sales,
        CASE 
            WHEN ci.total_profit > 10000 AND ci.order_count > 20 THEN 'Platinum'
            WHEN ci.total_profit BETWEEN 5000 AND 10000 THEN 'Gold'
            WHEN ci.total_profit BETWEEN 1000 AND 5000 THEN 'Silver'
            ELSE 'Bronze'
        END AS customer_tier
    FROM 
        FilteredSales fs
    LEFT JOIN 
        CustomerInfo ci ON fs.web_site_id = ci.c_customer_id
)
SELECT 
    f.web_site_id,
    f.customer_tier,
    f.total_sales,
    f.order_count,
    COALESCE(f.total_profit, 0) AS total_profit,
    (SELECT COUNT(*) FROM customer WHERE c_first_name LIKE 'A%' AND c_last_name IS NOT NULL) AS a_name_customers_count 
FROM 
    FinalSales f
WHERE 
    f.total_sales IS NOT NULL
ORDER BY 
    f.total_sales DESC;
