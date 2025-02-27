
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ROW_NUMBER() OVER(PARTITION BY cd.cd_gender ORDER BY c.c_birth_year, c.c_birth_month DESC) AS rnk
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IN ('M', 'S') 
        AND cd.cd_credit_rating IS NOT NULL
),
CustomerSales AS (
    SELECT 
        cs.cs_customer_sk,
        SUM(cs.cs_net_paid) AS total_spent,
        COUNT(cs.cs_order_number) AS orders_count
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.cs_customer_sk
),
RecentSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_paid) AS recent_total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '30 days')
    GROUP BY 
        ws.ws_bill_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    COALESCE(cs.total_spent, 0) AS total_spent,
    COALESCE(rs.recent_total_sales, 0) AS recent_total_sales,
    CASE 
        WHEN COALESCE(cs.total_spent, 0) > 1000 THEN 'High Value'
        WHEN COALESCE(cs.total_spent, 0) BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_category
FROM 
    RankedCustomers rc
LEFT JOIN 
    CustomerSales cs ON rc.c_customer_sk = cs.cs_customer_sk
LEFT JOIN 
    RecentSales rs ON rc.c_customer_sk = rs.ws_bill_customer_sk
WHERE 
    rc.rnk = 1
    AND rc.cd_marital_status = 'S'
ORDER BY 
    total_spent DESC NULLS LAST
FETCH FIRST 100 ROWS ONLY;
