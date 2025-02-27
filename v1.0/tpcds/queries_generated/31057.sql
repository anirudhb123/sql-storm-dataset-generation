
WITH RECURSIVE CategoryHierarchy AS (
    SELECT i_category_id AS category_id, i_category AS category_name, 0 AS level
    FROM item
    WHERE i_item_sk IN (SELECT sr_item_sk FROM store_returns WHERE sr_return_quantity > 0)
    UNION ALL
    SELECT i_category_id, i_category, level + 1
    FROM item
    JOIN CategoryHierarchy ON item.i_category_id = CategoryHierarchy.category_id
    WHERE level < 3
),
SalesData AS (
    SELECT
        ws_sold_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_sold_date_sk
),
CustomerStats AS (
    SELECT
        cd_demo_sk,
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        SUM(ws_net_paid) AS total_spent,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_demographics
    LEFT JOIN customer ON customer.c_current_cdemo_sk = customer_demographics.cd_demo_sk
    LEFT JOIN web_sales ON web_sales.ws_bill_customer_sk = customer.c_customer_sk
    GROUP BY cd_demo_sk, cd_gender
)
SELECT
    d.d_date AS sale_date,
    COALESCE(sd.total_quantity, 0) AS total_quantity,
    COALESCE(sd.total_sales, 0) AS total_sales,
    cs.customer_count,
    cs.total_spent,
    cs.avg_purchase_estimate,
    ch.category_name,
    ROW_NUMBER() OVER (PARTITION BY ch.category_name ORDER BY COALESCE(sd.total_sales, 0) DESC) AS rank
FROM date_dim d
LEFT JOIN SalesData sd ON d.d_date_sk = sd.ws_sold_date_sk
LEFT JOIN CustomerStats cs ON cs.cd_demo_sk IN (SELECT cd_demo_sk FROM customer_demographics)
LEFT JOIN CategoryHierarchy ch ON ch.category_id IN (SELECT DISTINCT i_category_id FROM item)
WHERE d.d_year = 2023
ORDER BY d.d_date, ch.category_name;
