
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY cd.cd_purchase_estimate DESC) AS purchase_rank
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_ship_customer_sk
),
ReturnData AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_return_amt) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
CombinedData AS (
    SELECT
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        sd.total_sales,
        COALESCE(rd.total_returns, 0) AS total_returns,
        sd.order_count
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_ship_customer_sk
    LEFT JOIN 
        ReturnData rd ON cd.c_customer_sk = rd.refunded_customer_sk
    WHERE 
        cd.purchase_rank = 1
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    CASE 
        WHEN c.total_sales IS NULL OR c.total_sales <= 0 THEN 'No sales'
        WHEN c.total_returns > c.total_sales * 0.1 THEN 'High Return Rate'
        ELSE 'Normal'
    END AS sales_status,
    c.total_sales,
    c.total_returns,
    (c.total_sales - c.total_returns) AS net_sales
FROM 
    CombinedData c
ORDER BY 
    net_sales DESC
LIMIT 50;
