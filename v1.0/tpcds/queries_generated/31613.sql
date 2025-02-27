
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        c.c_birth_year,
        1 AS level
    FROM customer c
    WHERE c.c_birth_year IS NOT NULL
    UNION ALL
    SELECT
        s.ss_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_current_addr_sk,
        c.c_birth_year,
        sh.level + 1
    FROM store_sales s
    JOIN customer c ON s.ss_customer_sk = c.c_customer_sk
    JOIN sales_hierarchy sh ON s.ss_customer_sk = sh.c_customer_sk
    WHERE sh.level < 5
),
customer_demos AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM customer_demographics cd
    LEFT JOIN (
        SELECT 
            ws_bill_cdemo_sk AS cdemo_sk,
            SUM(ws_net_paid) AS ws_net_paid
        FROM web_sales 
        GROUP BY ws_bill_cdemo_sk
    ) AS ws ON cd.cd_demo_sk = ws.cdemo_sk
    GROUP BY cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status
),
top_customers AS (
    SELECT
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(s.ws_net_paid) DESC) AS rank,
        cd.cd_gender,
        SUM(s.ws_net_paid) AS total_spent
    FROM web_sales s
    JOIN customer c ON s.ws_ship_customer_sk = c.c_customer_sk
    JOIN customer_demos cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender, c.c_current_cdemo_sk
)
SELECT
    ca.ca_city,
    ca.ca_state,
    sh.c_first_name,
    sh.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    SUM(ws.ws_net_paid_inc_tax) AS total_spent_in_tax,
    COUNT(DISTINCT ws.ws_order_number) AS order_count,
    CASE
        WHEN SUM(ws.ws_net_paid_inc_tax) IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS sales_status
FROM sales_hierarchy sh
JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
LEFT JOIN customer_demos cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE ca.ca_state IS NOT NULL 
GROUP BY ca.ca_city, ca.ca_state, sh.c_first_name, sh.c_last_name, cd.cd_gender, cd.cd_marital_status
HAVING SUM(ws.ws_net_paid_inc_tax) > 500 
OR COUNT(ws.ws_order_number) > 5
ORDER BY total_spent_in_tax DESC
LIMIT 10;
