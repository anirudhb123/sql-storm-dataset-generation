
WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
AnnualSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                            AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_bill_customer_sk
),
DemographicAnalysis AS (
    SELECT 
        cd.cd_demo_sk,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_dep_count) AS max_dependents
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
FinalAnalysis AS (
    SELECT 
        cs.c_customer_sk,
        as.total_sales,
        as.total_orders,
        ds.avg_purchase_estimate,
        cs.total_returns,
        cs.total_return_amount,
        ds.max_dependents
    FROM 
        CustomerStats cs
    LEFT JOIN 
        AnnualSales as ON cs.c_customer_sk = as.ws_bill_customer_sk
    LEFT JOIN 
        DemographicAnalysis ds ON c.c_current_cdemo_sk = ds.cd_demo_sk
)
SELECT 
    fa.c_customer_sk,
    COALESCE(total_sales, 0) AS total_sales,
    COALESCE(total_orders, 0) AS total_orders,
    COALESCE(avg_purchase_estimate, 0) AS avg_purchase_estimate,
    COALESCE(total_returns, 0) AS total_returns,
    COALESCE(total_return_amount, 0) AS total_return_amount,
    COALESCE(max_dependents, 0) AS max_dependents
FROM 
    FinalAnalysis fa
ORDER BY 
    total_sales DESC
LIMIT 100;
