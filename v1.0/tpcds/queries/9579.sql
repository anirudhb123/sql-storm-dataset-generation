
WITH RankedReturns AS (
    SELECT 
        sr_returned_date_sk,
        sr_item_sk,
        sr_customer_sk,
        ROW_NUMBER() OVER (PARTITION BY sr_item_sk ORDER BY sr_returned_date_sk DESC) AS rnk
    FROM 
        store_returns
),
AggregateSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS sales_count
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
CustomerData AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    i.i_item_desc AS item_desc,
    a.total_sales,
    a.total_profit,
    c.gender,
    c.marital_status,
    COUNT(DISTINCT r.sr_customer_sk) AS returns_count,
    COALESCE(SUM(r.sr_return_amt), 0) AS total_returned_amount
FROM 
    AggregateSales a
JOIN 
    item i ON a.ws_item_sk = i.i_item_sk
JOIN 
    CustomerData c ON c.c_customer_sk IN (SELECT r.sr_customer_sk FROM RankedReturns r WHERE r.rnk = 1 AND r.sr_item_sk = a.ws_item_sk)
LEFT JOIN 
    store_returns r ON r.sr_item_sk = a.ws_item_sk
WHERE 
    a.total_sales > 500
GROUP BY 
    i.i_item_desc, a.total_sales, a.total_profit, c.gender, c.marital_status
ORDER BY 
    a.total_profit DESC;
