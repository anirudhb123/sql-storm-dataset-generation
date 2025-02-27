
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2458964 AND 2459477 -- Filter for specific date range
    GROUP BY c.c_customer_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
IncomeSummary AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cs.total_sales) AS total_sales,
        AVG(cs.order_count) AS avg_orders_per_customer
    FROM household_demographics h
    JOIN customer c ON h.hd_demo_sk = c.c_current_hdemo_sk
    JOIN CustomerSales cs ON c.c_customer_sk = cs.c_customer_sk
    GROUP BY h.hd_income_band_sk
)
SELECT 
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    is.customer_count,
    is.total_sales,
    is.avg_orders_per_customer
FROM IncomeSummary is
JOIN income_band ib ON is.hd_income_band_sk = ib.ib_income_band_sk
ORDER BY ib.ib_lower_bound;
