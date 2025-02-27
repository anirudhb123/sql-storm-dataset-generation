
WITH TotalSales AS (
    SELECT 
        ws_bill_cdemo_sk AS customer_demo_sk,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
CustomerInfo AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        TO_CHAR(CURRENT_DATE, 'YYYY') - cd.cd_birth_year AS age,
        CASE 
            WHEN cd.cd_purchase_estimate > 1000 THEN 'High'
            WHEN cd.cd_purchase_estimate <= 1000 AND cd.cd_purchase_estimate > 500 THEN 'Medium'
            ELSE 'Low'
        END AS purchase_category
    FROM 
        customer_demographics cd
),
RankedSales AS (
    SELECT 
        ti.customer_demo_sk,
        ti.total_sales,
        ti.order_count,
        RANK() OVER (PARTITION BY ti.customer_demo_sk ORDER BY ti.total_sales DESC) AS sales_rank
    FROM 
        TotalSales ti
)
SELECT 
    ci.cd_demo_sk,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.age,
    ci.purchase_category,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COALESCE(rs.order_count, 0) AS order_count,
    rs.sales_rank
FROM 
    CustomerInfo ci
LEFT JOIN 
    RankedSales rs ON ci.cd_demo_sk = rs.customer_demo_sk
WHERE 
    (ci.cd_gender = 'F' AND ci.purchase_category = 'High')
    OR (ci.cd_marital_status = 'M' AND rs.order_count > 5)
ORDER BY 
    total_sales DESC
FETCH FIRST 10 ROWS ONLY;
