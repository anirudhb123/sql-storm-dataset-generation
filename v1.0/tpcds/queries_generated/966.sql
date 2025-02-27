
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) as total_sales,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) as sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        RANK() OVER (ORDER BY cd.cd_purchase_estimate DESC) as purchase_rank
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
)
SELECT 
    cu.c_customer_id,
    cu.cd_gender,
    cu.cd_marital_status,
    cu.cd_purchase_estimate,
    COALESCE(rs.total_sales, 0) as total_sales,
    CASE 
        WHEN cu.purchase_rank <= 10 THEN 'Top 10 Purchasers'
        ELSE 'Other Customers' 
    END as customer_type
FROM 
    CustomerDetails cu
LEFT JOIN 
    RankedSales rs ON cu.c_customer_id = rs.ws_bill_customer_sk
WHERE 
    (cu.cd_marital_status = 'M' OR cu.cd_gender = 'F')
ORDER BY 
    total_sales DESC, cu.cd_purchase_estimate DESC
LIMIT 100;
