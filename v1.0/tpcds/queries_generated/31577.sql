
WITH RECURSIVE SalesCTE AS (
    SELECT ws_sold_date_sk, ws_item_sk, ws_quantity, ws_sales_price, ws_ext_sales_price,
           ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    WHERE ws_quantity > 0
    UNION ALL
    SELECT cs_sold_date_sk, cs_item_sk, cs_quantity, cs_sales_price, cs_ext_sales_price,
           ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY cs_sold_date_sk DESC) as rn
    FROM catalog_sales
    WHERE cs_quantity > 0
), RankedSales AS (
    SELECT ws_sold_date_sk AS sale_date, ws_item_sk AS item_id, SUM(ws_quantity) AS total_quantity,
           SUM(ws_ext_sales_price) AS total_sales, 
           DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) as sales_rank
    FROM web_sales
    WHERE ws_sales_price > 0
    GROUP BY ws_sold_date_sk, ws_item_sk
),
CustomerInfo AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cd_marital_status, cd_gender,
           COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name, cd_marital_status, cd_gender
)
SELECT
    ca_state,
    COUNT(DISTINCT ci.c_customer_sk) AS customer_count,
    SUM(ci.return_count) AS total_returns,
    AVG(s.total_sales) AS avg_sales_per_item,
    MAX(s.total_quantity) AS max_quantity_sold,
    MIN(s.total_quantity) AS min_quantity_sold
FROM customer_address ca
JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN CustomerInfo ci ON c.c_customer_sk = ci.c_customer_sk
LEFT JOIN RankedSales s ON s.item_id IN (SELECT i_item_sk FROM item WHERE i_current_price < 50)
WHERE ca.ca_state IS NOT NULL
GROUP BY ca_state
HAVING COUNT(DISTINCT ci.c_customer_sk) > 10
ORDER BY total_returns DESC, customer_count DESC;
