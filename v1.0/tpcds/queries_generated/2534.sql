
WITH CustomerWithReturns AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(sr_return_quantity), 0) AS total_return_quantity,
        COALESCE(SUM(sr_return_amt_inc_tax), 0) AS total_return_amt
    FROM customer c
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
WebSalesData AS (
    SELECT 
        ws_bill_customer_sk,
        COUNT(*) AS total_web_sales,
        SUM(ws_net_profit) AS total_web_net_profit
    FROM web_sales
    WHERE ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_date = CURRENT_DATE)
    GROUP BY ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM customer_demographics cd
    JOIN household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    cw.c_customer_id,
    cw.c_first_name,
    cw.c_last_name,
    cw.total_return_quantity,
    cw.total_return_amt,
    wd.total_web_sales,
    wd.total_web_net_profit,
    cd.cd_gender,
    cd.cd_marital_status,
    CASE 
        WHEN wd.total_web_sales > 10 THEN 'High' 
        WHEN wd.total_web_sales BETWEEN 1 AND 10 THEN 'Medium' 
        ELSE 'Low' 
    END AS sales_category,
    (SELECT COUNT(*) FROM inventory inv WHERE inv.inv_quantity_on_hand < 10) AS low_inventory_count
FROM CustomerWithReturns cw
LEFT JOIN WebSalesData wd ON cw.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_customer_sk = wd.ws_bill_customer_sk)
LEFT JOIN CustomerDemographics cd ON cw.c_customer_id = (SELECT c_customer_id FROM customer WHERE c_current_cdemo_sk = cd.cd_demo_sk)
ORDER BY cw.total_return_amt DESC, wd.total_web_net_profit DESC;
