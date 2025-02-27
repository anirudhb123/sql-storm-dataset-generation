
WITH ranked_sales AS (
    SELECT 
        cs_bill_customer_sk,
        cs_ship_mode_sk,
        SUM(cs_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY cs_bill_customer_sk ORDER BY SUM(cs_ext_sales_price) DESC) AS sales_rank
    FROM catalog_sales
    WHERE cs_sold_date_sk >= (
        SELECT MAX(d_date_sk)
        FROM date_dim
        WHERE d_date = CURDATE() -- current date
    ) - 30
    GROUP BY cs_bill_customer_sk, cs_ship_mode_sk
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        ci.c_current_addr_sk,
        ca.ca_city,
        COUNT(ws.order_number) AS total_orders
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE c.c_birth_month = MONTH(CURDATE())
    GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, ci.c_current_addr_sk, ca.ca_city
),
monthly_summary AS (
    SELECT 
        d_c_month,
        SUM(total_sales) AS sales_total
    FROM ranked_sales
    JOIN date_dim dd ON ranked_sales.cs_sold_date_sk = dd.d_date_sk
    GROUP BY d_c_month
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.ca_city,
    ci.cd_gender,
    ms.sales_total,
    CASE 
        WHEN ms.sales_total > 1000 THEN 'High Value'
        WHEN ms.sales_total BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value_segment
FROM customer_info ci
JOIN monthly_summary ms ON ci.c_customer_id = ms.d_c_month
ORDER BY customer_value_segment DESC, ms.sales_total DESC;
