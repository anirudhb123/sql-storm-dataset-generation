
WITH processed_customer AS (
    SELECT 
        c.c_customer_sk, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        CASE 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Male' 
        END AS gender,
        COUNT(DISTINCT sr_ticket_number) AS return_count,
        SUM(sr_return_amt) AS total_return_amt
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd_gender
),
customer_benchmark AS (
    SELECT 
        p.cd_gender, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
        AVG(CASE WHEN return_count > 0 THEN return_count ELSE NULL END) AS avg_returns,
        SUM(total_return_amt) AS total_return_amt,
        RANK() OVER (ORDER BY AVG(CASE WHEN return_count > 0 THEN return_count ELSE NULL END) DESC) AS return_rank
    FROM processed_customer p
    LEFT JOIN customer_demographics cd ON p.gender = 
        CASE 
            WHEN cd_gender = 'F' THEN 'Female' 
            ELSE 'Male' 
        END
    GROUP BY p.cd_gender
)
SELECT 
    cd_gender,
    customer_count,
    avg_returns,
    total_return_amt,
    return_rank
FROM customer_benchmark
WHERE customer_count > 10
ORDER BY return_rank;
