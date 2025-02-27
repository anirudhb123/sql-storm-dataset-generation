
WITH RECURSIVE CustomerHierarchy AS (
    SELECT c_customer_sk, c_first_name, c_last_name, c_current_addr_sk, 1 AS level
    FROM customer
    WHERE c_current_addr_sk IS NOT NULL

    UNION ALL

    SELECT c.customer_sk, c.c_first_name, c.c_last_name, c.c_current_addr_sk, ch.level + 1
    FROM customer c
    INNER JOIN CustomerHierarchy ch ON c.c_current_addr_sk = ch.c_current_addr_sk
    WHERE ch.level < 5
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk AS customer_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ws_ext_sales_price) AS median_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_bill_customer_sk
),
RankedSales AS (
    SELECT 
        sd.customer_sk,
        sd.total_sales,
        sd.order_count,
        sd.median_sales,
        RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY sd.order_count ORDER BY sd.total_sales DESC) AS order_rank
    FROM SalesData sd
),
CustomerWithDemographics AS (
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        r.r_reason_desc AS return_reason
    FROM CustomerHierarchy ch
    LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = ch.c_current_addr_sk
    LEFT JOIN store_returns sr ON sr.sr_customer_sk = ch.c_customer_sk
    LEFT JOIN reason r ON r.r_reason_sk = sr.sr_reason_sk
)
SELECT 
    cwd.c_customer_sk,
    cwd.c_first_name,
    cwd.c_last_name,
    cwd.cd_gender,
    cwd.cd_marital_status,
    rs.total_sales,
    rs.order_count,
    rs.median_sales,
    rs.sales_rank,
    rs.order_rank,
    COUNT(DISTINCT sr_ticket_number) AS total_returns,
    MAX(CASE WHEN sr_return_quantity IS NULL THEN 0 ELSE sr_return_quantity END) AS max_return_quantity
FROM CustomerWithDemographics cwd
JOIN RankedSales rs ON cwd.c_customer_sk = rs.customer_sk
LEFT JOIN store_returns sr ON sr.sr_customer_sk = cwd.c_customer_sk
GROUP BY cwd.c_customer_sk, cwd.c_first_name, cwd.c_last_name, cwd.cd_gender, cwd.cd_marital_status, 
         rs.total_sales, rs.order_count, rs.median_sales, rs.sales_rank, rs.order_rank
HAVING COUNT(DISTINCT sr_ticket_number) > 0 OR rs.total_sales > 1000
ORDER BY rs.sales_rank, cwd.c_last_name;
