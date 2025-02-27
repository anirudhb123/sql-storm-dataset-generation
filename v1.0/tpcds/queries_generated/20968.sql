
WITH RECURSIVE AddressCTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_zip, ca_country 
    FROM customer_address 
    WHERE ca_country = 'USA'
    UNION ALL
    SELECT a.ca_address_sk, a.ca_city, a.ca_state, a.ca_zip, a.ca_country 
    FROM customer_address a
    JOIN AddressCTE cte ON a.ca_state = cte.ca_state
    WHERE a.ca_city <> cte.ca_city
), CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female' 
            ELSE 'Other' 
        END AS gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr_item_sk) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amt,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_net_profit) AS total_net_profit,
        AVG(cd.cd_dep_count) OVER (PARTITION BY cd.cd_gender) AS avg_dependents
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
        AND cd.cd_credit_rating IS NOT NULL
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), ReturnAnalysis AS (
    SELECT 
        gender,
        SUM(total_returns) AS total_returns,
        SUM(total_net_profit) AS total_net_profit,
        COUNT(*) AS customer_count
    FROM CustomerStats
    GROUP BY gender
), DetailedReturns AS (
    SELECT 
        a.ca_city, 
        r.gender,
        r.total_returns,
        r.total_net_profit,
        r.customer_count,
        ROW_NUMBER() OVER (PARTITION BY a.ca_city ORDER BY r.total_net_profit DESC) AS city_rank
    FROM AddressCTE a
    LEFT JOIN ReturnAnalysis r ON a.ca_city = (
        SELECT 
            c.c_customer_sk
        FROM customer c
        WHERE c.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_city = a.ca_city)
        LIMIT 1
    )
    WHERE a.ca_zip IS NOT NULL
)
SELECT 
    city_rank,
    ca_city,
    gender,
    total_returns,
    total_net_profit,
    customer_count
FROM DetailedReturns
WHERE gender IS NOT NULL
AND total_returns > 10
ORDER BY total_net_profit DESC
LIMIT 10;
