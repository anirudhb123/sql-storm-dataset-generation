
WITH RECURSIVE sales_totals AS (
    SELECT
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(ws_order_number) AS order_count
    FROM
        web_sales
    GROUP BY
        ws_item_sk
    UNION ALL
    SELECT
        c.cs_item_sk,
        SUM(c.cs_sales_price * c.cs_quantity) AS total_sales,
        COUNT(c.cs_order_number) AS order_count
    FROM
        catalog_sales c
    JOIN sales_totals s ON c.cs_item_sk = s.ws_item_sk
    GROUP BY
        c.cs_item_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_web_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
address_info AS (
    SELECT
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    COALESCE(st.total_sales, 0) AS total_sales_web,
    COALESCE(st.order_count, 0) AS total_orders_web,
    COALESCE(ai.customer_count, 0) AS customers_in_city,
    ai.ca_city,
    ai.ca_state
FROM
    customer_info ci
LEFT JOIN sales_totals st ON ci.c_customer_sk = st.ws_item_sk
LEFT JOIN address_info ai ON ci.c_current_addr_sk = ai.ca_address_sk
WHERE
    (ci.total_web_spent IS NULL OR ci.total_web_spent > 1000)
    AND (ci.cd_gender = 'F' OR ci.cd_marital_status = 'M')
ORDER BY
    ci.total_web_spent DESC, ci.c_last_name;
