
WITH RECURSIVE income_range AS (
    SELECT 
        ib_income_band_sk,
        ib_lower_bound,
        ib_upper_bound,
        CAST(NULL AS decimal(10,2)) AS avg_income
    FROM income_band
    UNION ALL
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        (ib.ib_lower_bound + ib.ib_upper_bound) / 2 AS avg_income
    FROM income_band ib
    JOIN income_range ir ON ir.ib_income_band_sk = ib.ib_income_band_sk
    WHERE ir.avg_income IS NULL
),
customer_data AS (
    SELECT 
        c.c_customer_id,
        d.d_date,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_ranking,
        DENSE_RANK() OVER (ORDER BY cd.cd_marital_status, cd.cd_purchase_estimate) AS marital_ranking
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON hd.hd_demo_sk = cd.cd_demo_sk
    JOIN date_dim d ON c.c_first_sales_date_sk = d.d_date_sk
),
sales_summary AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        AVG(ws.ws_net_profit) AS average_profit
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_id
)
SELECT 
    cust.c_customer_id,
    COALESCE(sale.total_orders, 0) AS total_orders,
    COALESCE(sale.total_sales, 0.00) AS total_sales,
    CASE 
        WHEN sale.average_profit IS NULL THEN 'No Profit'
        ELSE CASE 
            WHEN sale.average_profit > 100 THEN 'High Profit'
            WHEN sale.average_profit BETWEEN 50 AND 100 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END 
    END AS profit_category,
    ir.avg_income
FROM customer_data cust
LEFT JOIN sales_summary sale ON cust.c_customer_id = sale.c_customer_id
LEFT JOIN income_range ir ON cust.income_band = ir.ib_income_band_sk
WHERE customer_data.gender_ranking <= 10
  AND (cust.marital_ranking IS NULL OR cust.marital_ranking < 5)
ORDER BY total_sales DESC, cust.c_customer_id
LIMIT 100 OFFSET 0;
