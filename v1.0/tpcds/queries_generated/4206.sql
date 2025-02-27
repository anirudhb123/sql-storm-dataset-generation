
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amount,
        AVG(sr_return_quantity) AS avg_return_quantity
    FROM store_returns
    GROUP BY sr_customer_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        ir.ib_lower_bound,
        ir.ib_upper_bound
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inventory inv ON c.c_current_addr_sk = inv.inv_item_sk
),
PerformanceMetrics AS (
    SELECT 
        cd.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cr.total_returns, 0) AS total_returns,
        COALESCE(cr.total_return_amount, 0.00) AS total_return_amount,
        COALESCE(sd.total_sales, 0.00) AS total_sales,
        sd.order_count,
        CASE WHEN COALESCE(sd.total_sales, 0.00) > 0 THEN (COALESCE(cr.total_return_amount, 0.00) / sd.total_sales) * 100 ELSE NULL END AS return_percentage
    FROM CustomerDemographics cd
    LEFT JOIN CustomerReturns cr ON cd.c_customer_sk = cr.sr_customer_sk
    LEFT JOIN SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    pm.cd_gender,
    pm.cd_marital_status,
    SUM(pm.total_returns) AS total_returns,
    SUM(pm.total_return_amount) AS total_return_amount,
    SUM(pm.total_sales) AS total_sales,
    AVG(pm.return_percentage) AS avg_return_percentage,
    COUNT(DISTINCT pm.c_customer_sk) AS unique_customers
FROM PerformanceMetrics pm
GROUP BY pm.cd_gender, pm.cd_marital_status
ORDER BY total_sales DESC, total_returns DESC;
