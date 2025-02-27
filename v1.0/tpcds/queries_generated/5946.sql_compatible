
WITH CustomerReturns AS (
    SELECT 
        sr_cdemo_sk, 
        SUM(sr_return_quantity) AS total_returned_quantity, 
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_cdemo_sk
),
WebSales AS (
    SELECT 
        ws_bill_cdemo_sk, 
        COUNT(ws_order_number) AS total_orders, 
        SUM(ws_net_profit) AS total_net_profit,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_bill_cdemo_sk
),
Demographics AS (
    SELECT 
        cd_demo_sk, 
        cd_gender, 
        cd_marital_status, 
        ib_income_band_sk 
    FROM 
        customer_demographics 
    LEFT JOIN 
        household_demographics ON cd_demo_sk = hd_demo_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(cr.total_returned_quantity, 0) AS total_returns,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(ws.total_orders, 0) AS total_web_orders,
    COALESCE(ws.total_net_profit, 0) AS total_net_profit,
    COALESCE(ws.total_sales, 0) AS total_web_sales
FROM 
    Demographics d
LEFT JOIN 
    CustomerReturns cr ON d.cd_demo_sk = cr.sr_cdemo_sk
LEFT JOIN 
    WebSales ws ON d.cd_demo_sk = ws.ws_bill_cdemo_sk
LEFT JOIN 
    income_band ib ON d.ib_income_band_sk = ib.ib_income_band_sk
WHERE 
    ib.ib_lower_bound IS NOT NULL
ORDER BY 
    ib.ib_lower_bound;
