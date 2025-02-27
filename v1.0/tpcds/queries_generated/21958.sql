
WITH ranked_sales AS (
    SELECT 
        ss_customer_sk,
        ss_item_sk,
        ss_net_profit,
        RANK() OVER (PARTITION BY ss_customer_sk ORDER BY ss_net_profit DESC) AS profit_rank,
        COUNT(*) OVER (PARTITION BY ss_customer_sk) AS total_sales
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk BETWEEN 2450110 AND 2450220 -- Example date range
        AND ss_quantity > 5
),
top_customers AS (
    SELECT 
        distinct ca_address_id,
        ca_city,
        ca_state,
        ca_country,
        cd_credit_rating,
        cd_purchase_estimate,
        (
            SELECT COUNT(*)
            FROM customer 
            WHERE c_customer_sk = ss_customer_sk 
            AND c_birth_year IS NOT NULL
        ) AS customer_age_count
    FROM 
        customer_address
    JOIN 
        customer ON ca_address_sk = c_current_addr_sk
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    WHERE 
        cd_purchase_estimate > 10000
        AND ca_city IS NOT NULL
)
SELECT 
    tc.ca_address_id,
    tc.ca_city,
    tc.ca_state,
    tc.ca_country,
    tc.cd_credit_rating,
    tc.cd_purchase_estimate,
    SUM(rs.ss_net_profit) AS total_net_profit,
    SUM(rs.ss_net_profit) / NULLIF(COUNT(rs.ss_item_sk), 0) AS avg_net_profit,
    MAX(rs.profit_rank) AS max_profit_rank,
    SUM(CASE WHEN tc.customer_age_count > 0 THEN 1 ELSE 0 END) AS valid_age_count
FROM 
    top_customers tc
LEFT JOIN 
    ranked_sales rs ON tc.ca_address_id = CAST(rs.ss_customer_sk AS CHAR(16)) 
GROUP BY 
    tc.ca_address_id, tc.ca_city, tc.ca_state, tc.ca_country, tc.cd_credit_rating, tc.cd_purchase_estimate
HAVING 
    SUM(rs.ss_net_profit) > 5000
ORDER BY 
    avg_net_profit DESC, total_net_profit DESC
LIMIT 50;
