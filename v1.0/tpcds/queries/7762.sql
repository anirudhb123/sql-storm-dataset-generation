
WITH CustomerStats AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        SUM(CASE WHEN cd_marital_status = 'S' THEN 1 ELSE 0 END) AS single_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd_gender
),
SalesStats AS (
    SELECT 
        ws_bill_cdemo_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_cdemo_sk
),
ReturnStats AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns 
    GROUP BY 
        sr_customer_sk
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    cs.married_count,
    cs.single_count,
    COALESCE(ss.total_sales, 0) AS total_sales,
    COALESCE(ss.total_profit, 0) AS total_profit,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesStats ss ON cs.cd_gender = (SELECT cd_gender FROM customer_demographics WHERE cd_demo_sk = ss.ws_bill_cdemo_sk)
LEFT JOIN 
    ReturnStats rs ON cs.total_customers = rs.sr_customer_sk
ORDER BY 
    cs.cd_gender;
