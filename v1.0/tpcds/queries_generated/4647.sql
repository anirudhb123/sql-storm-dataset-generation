
WITH CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) + COALESCE(cs.cs_net_paid, 0)) AS total_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_count,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_sales_count
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeDistribution AS (
    SELECT
        h.hd_income_band_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cs.total_sales) AS average_sales
    FROM household_demographics h
    JOIN CustomerSales cs ON h.hd_demo_sk = cs.c_customer_sk
    GROUP BY h.hd_income_band_sk
),
RankedCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_sales,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM CustomerSales cs
    JOIN customer c ON cs.c_customer_sk = c.c_customer_sk
),
TopSellingCustomers AS (
    SELECT
        r.c_customer_sk,
        r.c_first_name,
        r.c_last_name,
        r.total_sales
    FROM RankedCustomers r
    WHERE r.sales_rank <= 10
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    COALESCE(id.customer_count, 0) AS customer_count_in_income_band,
    COALESCE(id.average_sales, 0) AS average_sales_in_income_band
FROM TopSellingCustomers tc
LEFT JOIN IncomeDistribution id ON id.hd_income_band_sk = (
    SELECT hd_demo_sk FROM household_demographics WHERE hd_demo_sk = tc.c_customer_sk
)
ORDER BY tc.total_sales DESC;
