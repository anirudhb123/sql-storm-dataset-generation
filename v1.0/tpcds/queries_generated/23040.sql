
WITH RECURSIVE item_hierarchy AS (
    SELECT i_item_sk, i_item_id, i_item_desc, i_current_price,
           ROW_NUMBER() OVER (PARTITION BY i_item_sk ORDER BY i_current_price DESC) as rn
    FROM item
    WHERE i_rec_start_date <= CURRENT_DATE AND (i_rec_end_date IS NULL OR i_rec_end_date > CURRENT_DATE)
),
customer_returns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt_inc_tax) AS avg_return_amt,
        COUNT(DISTINCT sr_item_sk) AS unique_items_returned,
        MAX(sr_return_time_sk) AS last_return_time,
        CASE 
            WHEN AVG(sr_return_amt) IS NULL THEN 'No Returns'
            WHEN AVG(sr_return_amt) > 100 THEN 'Frequent Returner'
            ELSE 'Occasional Returner'
        END AS return_category
    FROM store_returns 
    WHERE sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY sr_customer_sk
),
gross_sales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        DENSE_RANK() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_ship_date_sk IS NOT NULL
    GROUP BY ws_bill_customer_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    cd.cd_gender,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.avg_return_amt, 0) AS avg_return_amt,
    gs.total_sales,
    gs.total_orders,
    ci.i_item_desc,
    ci.rn AS item_ranking
FROM customer c
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_returns cr ON c.c_customer_sk = cr.sr_customer_sk
JOIN gross_sales gs ON c.c_customer_sk = gs.ws_bill_customer_sk
LEFT JOIN item_hierarchy ci ON ci.i_item_id = (
    SELECT i_item_id
    FROM item
    WHERE i_item_sk IN (
        SELECT sr_item_sk
        FROM store_returns
        WHERE sr_customer_sk = c.c_customer_sk
    ) 
    ORDER BY i_current_price DESC
    LIMIT 1
)
WHERE 
    (cd.cd_gender IS NULL OR cd.cd_marital_status = 'M')
    AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
    AND (gs.total_sales > (SELECT AVG(total_sales) FROM gross_sales) OR cr.total_returns IS NULL)
ORDER BY c.c_customer_id
LIMIT 50;
