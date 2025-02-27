
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws 
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
TotalReturned AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returned
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_marital_status, 'Unknown') AS marital_status,
        (CASE 
            WHEN hd.hd_income_band_sk IS NOT NULL THEN 'Income Band ' || hd.hd_income_band_sk 
            ELSE 'No Income Band'
         END) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_price,
        COUNT(ws.ws_order_number) AS order_count,
        COALESCE(ts.total_returned, 0) AS total_returns
    FROM 
        web_sales ws
    JOIN 
        CustomerStats c ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        TotalReturned ts ON c.c_customer_sk = ts.cr_returning_customer_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    s.c_customer_sk, 
    s.total_sales,
    s.average_price,
    s.order_count,
    s.total_returns,
    (s.total_sales - s.total_returns) AS net_sales,
    (CASE 
        WHEN s.order_count > 10 THEN 'High Value' 
        WHEN s.order_count BETWEEN 5 AND 10 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_segment
FROM 
    SalesSummary s
WHERE 
    s.total_sales > (
        SELECT 
            AVG(total_sales) 
        FROM 
            SalesSummary
    )
ORDER BY 
    s.total_sales DESC
LIMIT 10;
