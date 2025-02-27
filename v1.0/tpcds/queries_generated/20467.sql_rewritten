WITH RECURSIVE high_income_customers AS (
    SELECT c_customer_sk, c_first_name, c_last_name, cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Excellent'
    UNION ALL
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_credit_rating
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN high_income_customers hic ON c.c_customer_sk = hic.c_customer_sk 
    WHERE cd.cd_credit_rating <> 'Poor'
),
most_returned_items AS (
    SELECT sr_item_sk, COUNT(*) AS return_count
    FROM store_returns
    GROUP BY sr_item_sk
    HAVING COUNT(*) > 10
),
item_info AS (
    SELECT i.i_item_sk, i.i_item_desc, i.i_current_price,
           ROW_NUMBER() OVER (PARTITION BY i.i_item_sk ORDER BY i.i_current_price DESC) AS price_rank
    FROM item i
    JOIN most_returned_items mri ON i.i_item_sk = mri.sr_item_sk
),
combined_info AS (
    SELECT hic.c_customer_sk, hic.c_first_name, hic.c_last_name, ii.i_item_sk, ii.i_item_desc, ii.i_current_price,
           RANK() OVER (PARTITION BY hic.c_customer_sk ORDER BY ii.i_current_price DESC) AS item_rank
    FROM high_income_customers hic
    CROSS JOIN item_info ii
)
SELECT c.c_first_name, c.c_last_name, i.i_item_desc, i.i_current_price
FROM combined_info ci
JOIN customer c ON ci.c_customer_sk = c.c_customer_sk
JOIN item_info i ON ci.i_item_sk = i.i_item_sk
WHERE ci.item_rank = 1
AND ci.i_current_price IS NOT NULL
ORDER BY c.c_last_name, c.c_first_name;