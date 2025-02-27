
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) as rn
    FROM web_sales
    GROUP BY ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) as gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
TopSellingItems AS (
    SELECT 
        i.i_item_id,
        s.total_quantity,
        s.total_sales,
        RANK() OVER (ORDER BY s.total_sales DESC) AS item_rank
    FROM SalesData s
    JOIN item i ON s.ws_item_sk = i.i_item_sk
    WHERE s.total_quantity > 0
)

SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_sales,
    cs.total_quantity,
    CASE 
        WHEN c.c_birth_month IS NULL THEN 'Unknown'
        ELSE CONCAT(DATE_FORMAT(CONCAT_WS('-', c.c_birth_year, c.c_birth_month, c.c_birth_day), '%Y-%m-%d'), ' - ', c.c_birth_country)
    END AS customer_birth_info,
    tsi.i_item_id,
    tsi.total_sales AS item_sales,
    tsi.item_rank
FROM customer c
JOIN CustomerStats cs ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN TopSellingItems tsi ON cs.gender_rank = tsi.item_rank
WHERE cs.purchase_estimate > 1000
  AND (cs.cd_marital_status = 'M' OR cs.cd_marital_status IS NULL)
ORDER BY item_sales DESC, customer_birth_info;
