
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(CASE 
            WHEN s.ss_sales_price IS NOT NULL THEN s.ss_sales_price * s.ss_quantity 
            ELSE 0 
        END) AS total_store_sales,
        SUM(CASE 
            WHEN w.ws_sales_price IS NOT NULL THEN w.ws_sales_price * w.ws_quantity 
            ELSE 0 
        END) AS total_web_sales,
        COUNT(DISTINCT s.ss_ticket_number) AS store_transactions,
        COUNT(DISTINCT w.ws_order_number) AS web_transactions
    FROM 
        customer c
    LEFT JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    LEFT JOIN 
        web_sales w ON c.c_customer_sk = w.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_id
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer_demographics cd 
)
SELECT 
    cs.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    COALESCE(cs.total_store_sales, 0) AS total_store_sales,
    COALESCE(cs.total_web_sales, 0) AS total_web_sales,
    cs.store_transactions,
    cs.web_transactions
FROM 
    CustomerSales cs
JOIN 
    CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk 
WHERE 
    (cs.total_store_sales + cs.total_web_sales) > 1000
ORDER BY 
    total_store_sales DESC, total_web_sales DESC
LIMIT 50;
