
WITH RankedSales AS (
    SELECT 
        s_store_sk, 
        s_item_sk, 
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        DENSE_RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS rank_sales
    FROM store_sales
    WHERE ss_sold_date_sk IN (
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2023 AND d_month_seq BETWEEN 1 AND 3 
        UNION 
        SELECT d_date_sk 
        FROM date_dim 
        WHERE d_year = 2022 AND d_month_seq BETWEEN 10 AND 12
    )
    GROUP BY s_store_sk, s_item_sk
),
TopStores AS (
    SELECT 
        s_store_sk,
        AVG(total_net_paid) AS avg_net_paid
    FROM RankedSales
    WHERE rank_sales <= 10
    GROUP BY s_store_sk
),
AddressWithSteepDiscounts AS (
    SELECT 
        ca_address_sk, 
        ca_city, 
        ca_state, 
        COUNT(DISTINCT sr_returned_date_sk) AS return_count 
    FROM customer_address AS ca
    JOIN store_returns AS sr 
        ON ca.ca_address_sk = sr.sr_addr_sk 
    WHERE sr_return_quantity > (
        SELECT AVG(sr_return_quantity) 
        FROM store_returns 
        WHERE sr_returned_date_sk IS NOT NULL
    )
    GROUP BY ca_address_sk, ca_city, ca_state
)
SELECT 
    T.s_store_sk, 
    A.ca_city, 
    A.ca_state,
    T.avg_net_paid,
    R.total_quantity,
    CASE 
        WHEN R.total_quantity = 0 THEN 'No Sales'
        WHEN A.return_count > 5 THEN 'High Returns'
        ELSE 'Normal'
    END AS return_status
FROM TopStores AS T
JOIN RankedSales AS R 
    ON T.s_store_sk = R.s_store_sk
LEFT JOIN AddressWithSteepDiscounts AS A 
    ON R.s_item_sk = (SELECT sr_item_sk FROM store_returns WHERE sr_customer_sk IS NOT NULL ORDER BY RANDOM() LIMIT 1)
WHERE T.avg_net_paid IS NOT NULL
AND (A.ca_city IS NOT NULL OR A.ca_state IS NOT NULL)
ORDER BY T.avg_net_paid DESC, A.ca_city;
