
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_id
),
IncomeRanges AS (
    SELECT 
        ib.ib_income_band_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM income_band ib
    WHERE (ib.ib_lower_bound IS NOT NULL OR ib.ib_upper_bound IS NOT NULL)
),
RankedSales AS (
    SELECT 
        cs.c_customer_id,
        cs.total_sales,
        RANK() OVER (PARTITION BY ir.ib_income_band_sk ORDER BY cs.total_sales DESC) AS sales_rank,
        ir.ib_income_band_sk
    FROM CustomerSales cs
    JOIN CustomerDemographics cd ON cs.c_customer_id = cd.cd_demo_sk
    LEFT JOIN IncomeRanges ir ON cd.cd_purchase_estimate BETWEEN ir.ib_lower_bound AND ir.ib_upper_bound
)
SELECT 
    r.c_customer_id,
    r.total_sales,
    COALESCE(r.sales_rank, 'No Rank') AS sales_rank,
    CASE WHEN r.total_sales IS NULL THEN 'No Sales'
         WHEN r.total_sales <= 1000 THEN 'Low-value customer'
         WHEN r.total_sales BETWEEN 1001 AND 5000 THEN 'Mid-value customer'
         ELSE 'High-value customer'
    END AS value_category
FROM RankedSales r 
WHERE 
    r.sales_rank <= 5 OR
    r.ib_income_band_sk IS NULL
ORDER BY r.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
