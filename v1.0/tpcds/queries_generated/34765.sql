
WITH RECURSIVE SalesHierarchy AS (
    SELECT 
        c_customer_sk,
        c_first_name,
        c_last_name,
        COALESCE(SUM(ss_net_profit), 0) AS total_profit,
        1 AS level
    FROM customer
    LEFT JOIN store_sales ON customer.c_customer_sk = store_sales.ss_customer_sk
    GROUP BY c_customer_sk, c_first_name, c_last_name
    UNION ALL
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.ws_net_profit), 0) + sh.total_profit AS total_profit,
        sh.level + 1
    FROM SalesHierarchy sh
    JOIN customer c ON sh.c_customer_sk = c.c_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, sh.total_profit, sh.level
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        cd.cd_dep_college_count,
        CASE
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other' 
        END AS gender_description
    FROM customer_demographics cd
),
DateRange AS (
    SELECT 
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_day_name
    FROM date_dim d
    WHERE d.d_date BETWEEN '2022-01-01' AND '2022-12-31'
),
ProfitableCustomers AS (
    SELECT 
        sh.c_customer_sk,
        sh.c_first_name,
        sh.c_last_name,
        sh.total_profit,
        cd.gender_description,
        dr.d_year
    FROM SalesHierarchy sh
    JOIN CustomerDemographics cd ON sh.c_customer_sk = cd.cd_demo_sk
    JOIN DateRange dr ON YEAR(dr.d_date) = d.d_year
    WHERE sh.total_profit > 1000
)
SELECT 
    pc.c_customer_sk,
    pc.c_first_name,
    pc.c_last_name,
    pc.total_profit,
    pc.gender_description,
    COUNT(DISTINCT dr.d_year) AS years_active,
    SUM(ws.ws_net_paid) AS total_paid,
    COUNT(ws.ws_order_number) AS total_orders
FROM ProfitableCustomers pc
LEFT JOIN web_sales ws ON pc.c_customer_sk = ws.ws_ship_customer_sk
LEFT JOIN DateRange dr ON YEAR(ws.ws_sold_date_sk) = dr.d_year
GROUP BY 
    pc.c_customer_sk, 
    pc.c_first_name, 
    pc.c_last_name, 
    pc.total_profit, 
    pc.gender_description
HAVING 
    COUNT(DISTINCT dr.d_year) > 1
ORDER BY total_profit DESC
LIMIT 50;
