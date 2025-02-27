
WITH RECURSIVE Address_CTE AS (
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_city IS NOT NULL
    UNION ALL
    SELECT ca_address_sk, ca_city, ca_state, ca_country
    FROM customer_address
    WHERE ca_state <> 'XX' AND ca_country = 'US'
),
Customer_Summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ss.ss_quantity, 0)) AS total_purchases,
        COUNT(DISTINCT ss.ss_ticket_number) AS unique_sales,
        COUNT(DISTINCT sr.sr_ticket_number) AS total_returns,
        DATE_PART('year', CURRENT_DATE) - c.c_birth_year AS age,
        CASE WHEN COUNT(ss.ss_ticket_number) = 0 THEN 'No Purchases' ELSE 'Purchaser' END AS customer_status
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_id, cd.cd_gender, cd.cd_marital_status, c.c_birth_year
),
Web_Sales_Summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid) AS total_spent,
        COUNT(ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY total_spent DESC) AS order_rank
    FROM web_sales
    WHERE ws_net_paid > 100
    GROUP BY ws_bill_customer_sk
    HAVING COUNT(ws_order_number) > 5
),
Combined_Summary AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        COALESCE(ws.total_spent, 0) AS web_total_spent,
        cs.total_purchases,
        cs.unique_sales,
        cs.total_returns,
        CASE 
            WHEN cs.customer_status = 'Purchaser' AND ws.total_orders > 0 THEN 'Active Web User'
            ELSE 'Inactive Web User'
        END AS web_user_status
    FROM Customer_Summary cs
    LEFT JOIN Web_Sales_Summary ws ON cs.c_customer_id = ws.ws_bill_customer_sk
)
SELECT 
    ac.ca_city,
    ac.ca_state,
    cs.cd_gender,
    cs.web_total_spent,
    cs.total_purchases,
    cs.unique_sales,
    cs.total_returns,
    COUNT(DISTINCT cs.c_customer_id) AS customer_count,
    MAX(total_spent) FILTER (WHERE cs.web_user_status = 'Active Web User') AS max_active_spent,
    AVG(total_spent) FILTER (WHERE cs.web_user_status IS NOT NULL) AS avg_spent_active_users
FROM Address_CTE ac
JOIN Combined_Summary cs ON ac.ca_address_sk = cs.c_customer_id
GROUP BY ac.ca_city, ac.ca_state, cs.cd_gender
HAVING COUNT(cs.c_customer_id) > 0
ORDER BY ac.ca_state, ac.ca_city;
