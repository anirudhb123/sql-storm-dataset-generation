
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_return_quantity,
        SUM(cr.return_amt) AS total_return_amount,
        COUNT(DISTINCT cr.order_number) AS total_orders_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_city,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_bill_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk BETWEEN 20210101 AND 20211231
    GROUP BY 
        ws.ws_ship_date_sk, ws.ws_bill_customer_sk
),
ReturnAnalysis AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_return_quantity, 0) AS total_return_quantity,
        COALESCE(cr.total_return_amount, 0) AS total_return_amount,
        COALESCE(sd.total_sales, 0) AS total_sales,
        CASE 
            WHEN COALESCE(cr.total_return_quantity, 0) / NULLIF(sd.total_sales, 0) > 0.1 THEN 'High'
            ELSE 'Normal'
        END AS return_status
    FROM 
        CustomerDetails cd
        LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.returning_customer_sk
        LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    ra.c_customer_sk,
    ra.c_first_name,
    ra.c_last_name,
    ra.cd_gender,
    ra.cd_marital_status,
    ra.total_return_quantity,
    ra.total_return_amount,
    ra.total_sales,
    ra.return_status
FROM 
    ReturnAnalysis ra
WHERE 
    ra.total_sales > 0
ORDER BY 
    ra.total_return_amount DESC, ra.total_sales ASC;
