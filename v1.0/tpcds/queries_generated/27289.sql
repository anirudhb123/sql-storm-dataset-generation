
WITH RankedReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY COUNT(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.gender,
        cd.marital_status,
        cd.education_status
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        AVG(ws_sales_price) AS avg_sales_price,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ci.full_name,
    ci.gender,
    ci.marital_status,
    ci.education_status,
    rr.total_returns,
    rr.total_return_amount,
    asales.total_sales,
    asales.avg_sales_price,
    asales.total_quantity
FROM 
    CustomerInfo ci
JOIN 
    RankedReturns rr ON rr.sr_item_sk IN (SELECT sr_item_sk FROM store_returns)
JOIN 
    AggregateSales asales ON asales.ws_item_sk = rr.sr_item_sk
WHERE 
    rr.rn = 1
ORDER BY 
    rr.total_returns DESC, asales.total_sales DESC
LIMIT 100;
