
WITH CTE_Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_paid), 0) AS total_web_sales,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_catalog_sales,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_store_sales
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
CTE_Average_Sales AS (
    SELECT
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_catalog_sales) AS avg_catalog_sales,
        AVG(total_store_sales) AS avg_store_sales
    FROM 
        CTE_Customer_Sales
),
CTE_Demographics AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        COUNT(*) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate, cd.cd_credit_rating
),
Final_Report AS (
    SELECT 
        cs.c_first_name,
        cs.c_last_name,
        cs.total_web_sales,
        cs.total_catalog_sales,
        cs.total_store_sales,
        CASE 
            WHEN cs.total_web_sales > avg.avg_web_sales THEN 'Above Average'
            WHEN cs.total_web_sales < avg.avg_web_sales THEN 'Below Average'
            ELSE 'Average'
        END AS web_sales_performance,
        d.cd_gender,
        d.cd_marital_status,
        d.cd_purchase_estimate,
        d.cd_credit_rating
    FROM 
        CTE_Customer_Sales cs
    JOIN 
        CTE_Average_Sales avg ON 1=1
    CROSS JOIN 
        CTE_Demographics d
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_web_sales,
    fr.total_catalog_sales,
    fr.total_store_sales,
    fr.web_sales_performance,
    fr.cd_gender,
    fr.cd_marital_status,
    fr.cd_purchase_estimate,
    fr.cd_credit_rating,
    ROW_NUMBER() OVER(PARTITION BY fr.cd_gender ORDER BY fr.total_web_sales DESC) AS gender_rank
FROM 
    Final_Report fr
WHERE 
    fr.total_web_sales > 1000 OR fr.cd_marital_status = 'M'
ORDER BY 
    fr.total_web_sales DESC;
