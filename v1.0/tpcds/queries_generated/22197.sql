
WITH customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_dep_count,
        cd.cd_dep_employed_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
age_distribution AS (
    SELECT 
        c.c_customer_sk,
        EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year AS age,
        CASE 
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year < 18 THEN 'Under 18'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year BETWEEN 18 AND 25 THEN '18-25'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year BETWEEN 26 AND 35 THEN '26-35'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year BETWEEN 36 AND 45 THEN '36-45'
            WHEN EXTRACT(YEAR FROM CURRENT_DATE) - c.c_birth_year BETWEEN 46 AND 55 THEN '46-55'
            ELSE '55 and above'
        END AS age_group
    FROM customer_info c
),
top_cities AS (
    SELECT 
        ca.city,
        COUNT(*) AS total_customers
    FROM customer_address ca
    JOIN customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY ca.city
    ORDER BY total_customers DESC
    LIMIT 5
),
sales_data AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    GROUP BY ws_bill_customer_sk
),
return_stats AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_returned,
        COUNT(wr_order_number) AS return_count
    FROM web_returns
    GROUP BY wr_returning_customer_sk
),
final_stats AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ag.age,
        ag.age_group,
        ts.city AS top_city,
        COALESCE(sd.total_sales, 0) AS total_sales,
        COALESCE(rs.total_returned, 0) AS total_returned,
        (COALESCE(sd.total_sales, 0) - COALESCE(rs.total_returned, 0)) AS net_spent
    FROM customer_info ci
    LEFT JOIN age_distribution ag ON ci.c_customer_sk = ag.c_customer_sk
    LEFT JOIN top_cities ts ON ci.c_current_addr_sk IN (SELECT ca_address_sk FROM customer_address)
    LEFT JOIN sales_data sd ON ci.c_customer_sk = sd.ws_bill_customer_sk
    LEFT JOIN return_stats rs ON ci.c_customer_sk = rs.wr_returning_customer_sk
    WHERE 
        ci.c_customer_sk IS NOT NULL 
        AND (ag.age >= 18 OR ag.age IS NULL)
)

SELECT 
    *
FROM final_stats
WHERE net_spent > (SELECT AVG(net_spent) FROM final_stats)
AND (total_sales > 10000 OR total_returned IS NULL)
ORDER BY net_spent DESC;
