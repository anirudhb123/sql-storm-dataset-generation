
WITH customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_sk
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS avg_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate
    FROM 
        customer_demographics cd
)
SELECT 
    cs.c_customer_sk,
    ds.cd_gender,
    ds.cd_marital_status,
    ds.cd_education_status,
    cs.total_returns,
    cs.total_return_amount,
    ss.total_sales,
    ss.avg_net_profit
FROM 
    customer_summary cs
LEFT JOIN 
    sales_summary ss ON cs.c_customer_sk = ss.customer_sk
INNER JOIN 
    demographics ds ON cs.c_customer_sk = ds.cd_demo_sk
WHERE 
    cs.total_returns > 0
ORDER BY 
    cs.total_return_amount DESC, ss.total_sales DESC
LIMIT 50;
