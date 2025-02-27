
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk,
           ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_sales
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) - 30 FROM date_dim)
    GROUP BY ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           SUM(ws_quantity) AS total_quantity,
           SUM(ws_net_paid) AS total_sales
    FROM web_sales
    JOIN SalesCTE ON web_sales.ws_sold_date_sk = SalesCTE.ws_sold_date_sk - 1
    WHERE web_sales.ws_item_sk = SalesCTE.ws_item_sk
    GROUP BY ws_sold_date_sk, ws_item_sk
),
StoreSales AS (
    SELECT ss_item_sk,
           COUNT(DISTINCT ss_ticket_number) AS store_transaction_count,
           SUM(ss_ext_sales_price) AS total_store_sales
    FROM store_sales
    GROUP BY ss_item_sk
),
CustomerDemographics AS (
    SELECT cd_demo_sk,
           COUNT(DISTINCT c_customer_sk) AS customer_count,
           MAX(cd_purchase_estimate) AS max_estimate,
           MIN(cd_credit_rating) AS min_credit_rating
    FROM customer_demographics
    JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE cd_purchase_estimate IS NOT NULL
    GROUP BY cd_demo_sk
)
SELECT d.d_date AS sale_date,
       sa.ws_item_sk,
       sa.total_quantity AS web_quantity,
       sa.total_sales AS web_sales_amount,
       COALESCE(ss.store_transaction_count, 0) AS store_transactions,
       COALESCE(ss.total_store_sales, 0) AS total_store_sales_amount,
       cd.customer_count AS unique_customers,
       cd.max_estimate,
       cd.min_credit_rating
FROM date_dim d
JOIN SalesCTE sa ON d.d_date_sk = sa.ws_sold_date_sk
LEFT JOIN StoreSales ss ON ss.ss_item_sk = sa.ws_item_sk
LEFT JOIN CustomerDemographics cd ON cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_current_addr_sk IS NOT NULL LIMIT 1)
WHERE d.d_year = 2023
AND d.d_month_seq BETWEEN 1 AND 12
ORDER BY sale_date, sa.ws_item_sk;
