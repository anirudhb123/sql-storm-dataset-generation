
WITH CustomerReturns AS (
    SELECT
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt) AS total_returned_amt,
        SUM(sr_return_tax) AS total_returned_tax
    FROM store_returns
    GROUP BY sr_customer_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        h.hd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
),
DateSales AS (
    SELECT
        d.d_date_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year = 2023
    GROUP BY d.d_date_sk
),
SalesRanking AS (
    SELECT
        d.d_date_sk,
        total_sales,
        total_orders,
        average_sales_price,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM DateSales
)
SELECT
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    cr.total_returned_quantity,
    cr.total_returned_amt,
    cr.total_returned_tax,
    dr.total_sales,
    dr.total_orders,
    dr.average_sales_price,
    CASE
        WHEN cr.total_returned_amt IS NULL THEN 0
        ELSE cr.total_returned_amt / NULLIF(dr.total_sales, 0)
    END AS return_rate,
    sr.sales_rank
FROM CustomerDetails cd
LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
JOIN SalesRanking sr ON sr.d_date_sk IN (SELECT DISTINCT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023) 
LEFT JOIN DateSales dr ON cr.total_returned_quantity > 0
ORDER BY return_rate DESC, dr.total_sales DESC;
