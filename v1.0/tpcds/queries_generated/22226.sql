
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.item_sk,
        ws.ext_sales_price,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ext_sales_price DESC) AS sales_rank,
        COALESCE(NULLIF(ws.ext_sales_price, 0), 0.01) as adjusted_price
    FROM web_sales ws
    WHERE ws.sold_date_sk IN (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = (SELECT MAX(d_year) FROM date_dim)
    )
    AND ws.bill_customer_sk IS NOT NULL
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city || ', ' || ca.ca_state || ' ' || COALESCE(ca.ca_zip, '00000') AS full_address
    FROM customer_address ca
    WHERE ca.ca_country = 'USA'
),
customer_purchases AS (
    SELECT 
        c.c_customer_sk,
        SUM(rs.ext_sales_price) AS total_spent,
        COUNT(DISTINCT rs.item_sk) AS distinct_items_purchased
    FROM customer c
    JOIN ranked_sales rs ON c.c_customer_sk = rs.bill_customer_sk
    GROUP BY c.c_customer_sk
)
SELECT 
    cp.c_customer_sk,
    cp.total_spent,
    cp.distinct_items_purchased,
    CASE 
        WHEN cp.total_spent > 1000 THEN 'Gold'
        WHEN cp.total_spent BETWEEN 500 AND 1000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier,
    ai.full_address
FROM customer_purchases cp
LEFT JOIN address_info ai ON cp.c_customer_sk = ai.ca_address_sk
WHERE cp.distinct_items_purchased > (SELECT AVG(distinct_items_purchased) FROM customer_purchases)
      AND EXISTS (SELECT 1 FROM store_sales ss WHERE ss.ss_item_sk IN (
          SELECT item_sk FROM ranked_sales WHERE sales_rank <= 5) 
          AND ss.ss_customer_sk = cp.c_customer_sk)
ORDER BY cp.total_spent DESC
LIMIT 10;
