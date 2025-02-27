
WITH IncomeRange AS (
    SELECT 
        hd_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CASE 
            WHEN ib_lower_bound IS NULL OR ib_upper_bound IS NULL THEN 'Unknown'
            ELSE CONCAT(ib_lower_bound, ' - ', ib_upper_bound)
        END AS income_category
    FROM household_demographics
    LEFT JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
),
SalesData AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_cdemo_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk BETWEEN 2452617 AND 2452984
    GROUP BY ws_sold_date_sk, ws_bill_cdemo_sk
),
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(sd.total_profit, 0) AS total_profit,
        COALESCE(sd.total_orders, 0) AS total_orders,
        id.income_category
    FROM customer c
    LEFT JOIN SalesData sd ON c.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN IncomeRange id ON c.c_current_cdemo_sk = id.hd_income_band_sk
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    cs.total_orders,
    COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
    SUM(wr.wr_return_amt) AS total_returned_amount,
    CASE 
        WHEN cs.total_profit > 1000 THEN 'High Value'
        WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM CustomerSales cs
LEFT JOIN web_returns wr ON cs.c_customer_sk = wr.wr_returning_customer_sk
GROUP BY 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_profit,
    cs.total_orders
HAVING 
    cs.total_orders > 0
ORDER BY 
    total_profit DESC, 
    cs.c_last_name;
