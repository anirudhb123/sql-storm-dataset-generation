
WITH CustomerStats AS (
    SELECT
        c.c_customer_id,
        cd.cc_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year BETWEEN 1970 AND 1990
),
SalesSummary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2022)
    GROUP BY
        ws_bill_customer_sk
)
SELECT
    cs.c_customer_id,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.cd_purchase_estimate,
    cs.total_sales,
    cs.total_orders,
    cs.avg_net_profit,
    CASE 
        WHEN cs.cd_purchase_estimate > 500 THEN 'High Value'
        ELSE 'Low Value'
    END AS customer_value,
    RANK() OVER (PARTITION BY cs.cd_gender ORDER BY cs.total_sales DESC) AS sales_rank
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesSummary ss ON cs.c_customer_id = ss.ws_bill_customer_sk
WHERE 
    (cs.cd_marital_status = 'M' OR cs.cd_dep_count >= 3)
    AND (ss.total_sales IS NOT NULL OR ss.total_orders IS NOT NULL)
ORDER BY 
    customer_value ASC, 
    total_sales DESC; 
