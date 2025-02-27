
WITH RECURSIVE DateCTE AS (
    SELECT d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year BETWEEN 2018 AND 2023
    UNION ALL
    SELECT d_year, d_month_seq, d_date
    FROM date_dim
    WHERE d_year = DateCTE.d_year + 1 AND d_month_seq = DateCTE.d_month_seq
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(ws_net_profit) AS total_profit,
        SUM(sr_return_amt) AS total_return_amount
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
IncomeBandStats AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(CASE WHEN total_orders > 0 THEN 1 END) AS active_customers,
        SUM(total_profit) AS total_profit,
        SUM(total_return_amount) AS total_return_amount
    FROM CustomerStats cs
    JOIN household_demographics h ON cs.c_customer_sk = h.hd_demo_sk
    GROUP BY h.hd_income_band_sk
),
MonthlyStats AS (
    SELECT 
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS monthly_sales,
        SUM(ws_ext_tax) AS monthly_tax,
        SUM(CASE WHEN hs.total_profit IS NOT NULL THEN hs.total_profit ELSE 0 END) AS total_profit,
        SUM(CASE WHEN hs.total_return_amount IS NOT NULL THEN hs.total_return_amount ELSE 0 END) AS total_returns
    FROM web_sales ws
    JOIN DateCTE d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN CustomerStats hs ON ws.ws_bill_customer_sk = hs.c_customer_sk
    GROUP BY d.d_month_seq
)
SELECT 
    d_year,
    monthly_sales,
    monthly_tax,
    (total_profit - total_returns) AS net_profit
FROM MonthlyStats m
JOIN (
    SELECT DISTINCT d_year
    FROM DateCTE
) d ON 1=1
ORDER BY d_year, monthly_sales DESC;
