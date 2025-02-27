
WITH RECURSIVE sales_hierarchy AS (
    SELECT ss_store_sk, ss_sold_date_sk, ss_item_sk, ss_quantity, ss_net_paid, 1 AS level
    FROM store_sales
    WHERE ss_sold_date_sk = (SELECT MAX(ss_sold_date_sk) FROM store_sales)

    UNION ALL

    SELECT s.ss_store_sk, s.ss_sold_date_sk, s.ss_item_sk, s.ss_quantity, s.ss_net_paid, sh.level + 1
    FROM store_sales s
    JOIN sales_hierarchy sh ON s.ss_store_sk = sh.ss_store_sk AND s.ss_sold_date_sk < sh.ss_sold_date_sk
    WHERE sh.level < 5
),
aggregated_sales AS (
    SELECT
        ss_store_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM store_sales
    GROUP BY ss_store_sk
    HAVING SUM(ss_net_paid) > 1000
),
customer_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, cd.cd_gender, cd.cd_marital_status
),
return_analysis AS (
    SELECT
        wr.returning_customer_sk,
        SUM(wr.return_quantity) AS total_returns,
        SUM(wr.return_amt) AS total_return_amount,
        SUM(wr.return_tax) AS total_return_tax
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
)
SELECT
    sh.ss_store_sk,
    ais.total_quantity,
    ais.total_sales,
    ci.ca_city,
    ci.cd_gender,
    ci.cd_marital_status,
    ra.total_returns,
    ra.total_return_amount,
    ra.total_return_tax
FROM sales_hierarchy sh
JOIN aggregated_sales ais ON sh.ss_store_sk = ais.ss_store_sk
JOIN customer_info ci ON ci.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = sh.ss_item_sk LIMIT 1)
LEFT JOIN return_analysis ra ON ra.returning_customer_sk = sh.ss_item_sk
WHERE (ais.total_sales IS NOT NULL) AND (ci.customer_count > 0)
ORDER BY sh.ss_store_sk, ais.total_sales DESC;
