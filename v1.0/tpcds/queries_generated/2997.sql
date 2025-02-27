
WITH ranked_returns AS (
    SELECT 
        sr.returned_date_sk, 
        sr.return_time_sk, 
        sr.item_sk, 
        sr.customer_sk, 
        sr.cdemo_sk,
        sr.store_sk, 
        sr.return_quantity,
        sr.return_amt,
        DENSE_RANK() OVER (PARTITION BY sr.store_sk ORDER BY sr.return_quantity DESC) AS rank_per_store
    FROM store_returns sr
    WHERE sr.return_quantity IS NOT NULL
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
), 
item_summary AS (
    SELECT 
        i.i_item_id,
        COUNT(DISTINCT sr.ticket_number) AS return_count,
        SUM(sr.return_amt) AS total_return_amt
    FROM store_returns sr
    JOIN item i ON sr.item_sk = i.i_item_sk
    GROUP BY i.i_item_id
)
SELECT 
    cu.c_customer_id,
    cu.c_first_name,
    cu.c_last_name,
    cu.cd_gender,
    cu.cd_marital_status,
    r.return_quantity,
    r.return_amt,
    i.return_count,
    i.total_return_amt
FROM ranked_returns r
JOIN customer_info cu ON r.customer_sk = cu.c_customer_id
LEFT JOIN item_summary i ON r.item_sk = i.i_item_id
WHERE r.rank_per_store <= 5 
  AND r.return_amt IS NOT NULL 
  AND cu.cd_marital_status = 'M'
ORDER BY r.return_quantity DESC, cu.c_last_name, cu.c_first_name;
