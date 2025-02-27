
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(EXTRACT(YEAR FROM AGE(CURRENT_DATE, DATE(c.c_birth_year || '-' || c.c_birth_month || '-' || c.c_birth_day)))::INTEGER) AS age,
        GREATEST(COALESCE(cd.cd_dep_count, 0), COALESCE(hd.hd_dep_count, 0)) AS max_dependents
    FROM
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics AS hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating, cd.cd_dep_count, hd.hd_dep_count
),
high_value_customers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_orders,
        cs.total_profit,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM
        customer_stats AS cs
    WHERE
        cs.total_profit > (SELECT AVG(total_profit) FROM customer_stats)
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    COALESCE(ws_total_sales.ws_total_sales, 0) AS total_web_sales,
    COALESCE(ss_total_sales.ss_total_sales, 0) AS total_store_sales,
    COALESCE(cs.max_dependents, 0) AS max_dependents,
    CASE
        WHEN hv.rank IS NOT NULL THEN 'High Value'
        ELSE 'Regular'
    END AS customer_type
FROM
    customer_stats AS cs
LEFT JOIN (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_ext_sales_price) AS ws_total_sales
    FROM
        web_sales
    GROUP BY
        ws_bill_customer_sk
) AS ws_total_sales ON ws_total_sales.ws_bill_customer_sk = cs.c_customer_sk
LEFT JOIN (
    SELECT
        ss_customer_sk,
        SUM(ss_ext_sales_price) AS ss_total_sales
    FROM
        store_sales
    GROUP BY
        ss_customer_sk
) AS ss_total_sales ON ss_total_sales.ss_customer_sk = cs.c_customer_sk
LEFT JOIN high_value_customers AS hv ON cs.c_customer_sk = hv.c_customer_sk
WHERE
    (cs.total_orders > 5 OR cs.age < 30)
    AND (LOWER(cs.c_last_name) LIKE 'a%' OR cs.cd_gender = 'F')
ORDER BY
    cs.total_profit DESC
FETCH FIRST 10 ROWS ONLY;
