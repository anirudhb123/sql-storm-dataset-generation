
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(sr_return_quantity, 0)) AS total_returned_items,
        SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
IncomeLevel AS (
    SELECT 
        cd.cd_demo_sk, 
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            WHEN cd.cd_purchase_estimate < ib.ib_lower_bound THEN 'Below Minimum'
            WHEN cd.cd_purchase_estimate >= ib.ib_lower_bound AND cd.cd_purchase_estimate <= ib.ib_upper_bound THEN 'Within Range'
            ELSE 'Above Maximum'
        END AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
SalesSummary AS (
    SELECT 
        ws.ws_web_site_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_sales,
        AVG(ws_net_profit) AS average_profit
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_web_site_sk
)
SELECT 
    c.c_customer_id,
    cl.income_band,
    COALESCE(cr.total_returned_items, 0) AS total_returned_items,
    COALESCE(cr.total_returned_amount, 0) AS total_returned_amount,
    ss.total_orders,
    ss.total_sales,
    ss.average_profit
FROM 
    CustomerReturns cr
JOIN 
    IncomeLevel cl ON cr.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_cdemo_sk = cl.cd_demo_sk LIMIT 1)
LEFT JOIN 
    SalesSummary ss ON ss.ws_web_site_sk IN (SELECT ws.web_site_sk FROM web_site ws WHERE ws.web_name LIKE '%Shop%')
ORDER BY 
    total_returned_amount DESC, 
    total_returned_items DESC;
