
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        ws.web_name,
        d.d_year,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year = 2023
    GROUP BY ws.web_site_id, ws.web_name, d.d_year
),
CustomerData AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_quantity) AS total_quantity_by_customer,
        SUM(sd.total_sales) AS total_sales_by_customer
    FROM SalesData sd
    JOIN customer c ON c.c_customer_sk = sd.web_site_id
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, cd.cd_marital_status
),
ReturnData AS (
    SELECT 
        sr_returned_date_sk,
        SUM(sr_return_quantity) AS total_returns_quantity,
        SUM(sr_return_amt) AS total_returns_amt
    FROM store_returns
    GROUP BY sr_returned_date_sk
)
SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales,
    COALESCE(rd.total_returns_quantity, 0) AS total_returns_quantity,
    COALESCE(rd.total_returns_amt, 0) AS total_returns_amt
FROM CustomerData cd
LEFT JOIN SalesData sd ON cd.total_quantity_by_customer = sd.total_quantity
LEFT JOIN ReturnData rd ON rd.sr_returned_date_sk = 20230101
ORDER BY cd.cd_gender, cd.cd_marital_status;
