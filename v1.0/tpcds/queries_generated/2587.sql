
WITH CustomerReturns AS (
    SELECT
        c.c_customer_id,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amount
    FROM
        customer AS c
    LEFT JOIN
        store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY
        c.c_customer_id
),
SalesData AS (
    SELECT
        ws.ws_bill_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM
        web_sales AS ws
    GROUP BY
        ws.ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status = 'M' THEN 'Married'
            ELSE 'Single'
        END AS marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_demographics AS cd
    JOIN 
        customer AS c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    cd.gender,
    cd.marital_status,
    SUM(cr.total_returns) AS total_returns,
    SUM(cr.total_return_amount) AS total_return_amount,
    SUM(sd.total_sales) AS total_sales,
    COUNT(DISTINCT sd.ws_bill_customer_sk) AS unique_customers,
    AVG(sd.avg_net_profit) AS avg_net_profit
FROM 
    CustomerReturns AS cr
JOIN 
    SalesData AS sd ON cr.c_customer_id = sd.ws_bill_customer_sk
JOIN 
    CustomerDemographics AS cd ON sd.ws_bill_customer_sk = cd.cd_demo_sk
GROUP BY 
    cd.gender, cd.marital_status
ORDER BY 
    total_returns DESC, total_sales DESC
```
