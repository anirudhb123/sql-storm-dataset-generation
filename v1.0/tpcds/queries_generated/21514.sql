
WITH CustomerStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, -1) AS income_band,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, hd.hd_income_band_sk
),
TopCustomers AS (
    SELECT 
        c.customer_id, 
        c.first_name,
        c.last_name,
        rank() OVER (PARTITION BY c.income_band ORDER BY c.total_spent DESC) AS rank_within_band
    FROM 
        CustomerStats c
    WHERE 
        c.order_count > 5
),
SalesByTime AS (
    SELECT 
        DATE(d.d_date) AS sales_date,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023 AND d.d_week_seq IS NOT NULL
    GROUP BY 
        sales_date
),
AggregatedSales AS (
    SELECT 
        sales_date,
        total_net_profit,
        order_count,
        SUM(total_net_profit) OVER (ORDER BY sales_date) AS cumulative_profit,
        LAG(total_net_profit, 1, 0) OVER (ORDER BY sales_date) AS last_day_profit
    FROM 
        SalesByTime
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.income_band,
    a.sales_date,
    a.total_net_profit,
    a.cumulative_profit,
    CASE 
        WHEN a.last_day_profit > 0 THEN 'Gained'
        WHEN a.last_day_profit < 0 THEN 'Lost'
        ELSE 'No Change' 
    END AS profit_change,
    MAX(a.total_net_profit) OVER (PARTITION BY tc.income_band) AS max_profit_in_band
FROM 
    TopCustomers tc
JOIN 
    AggregatedSales a ON tc.customer_id = 'some_customer_id'  -- Assuming a filter for demonstration purposes, use an appropriate filtering.
WHERE 
    a.total_net_profit IS NOT NULL
ORDER BY 
    tc.income_band, a.sales_date DESC
UNION ALL
SELECT 
    'Aggregate' AS customer_id,
    NULL AS first_name,
    NULL AS last_name,
    ib.ib_income_band_sk,
    NULL,
    SUM(a.total_net_profit) AS total_net_profit,
    NULL,
    NULL,
    NULL,
    MAX(a.total_net_profit) OVER (PARTITION BY ib.ib_income_band_sk) AS max_profit_in_band
FROM 
    AggregatedSales a
LEFT JOIN 
    income_band ib ON a.total_net_profit BETWEEN ib.ib_lower_bound AND ib.ib_upper_bound
GROUP BY 
    ib.ib_income_band_sk
ORDER BY 
    customer_id;
