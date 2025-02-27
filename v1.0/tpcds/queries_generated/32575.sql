
WITH RECURSIVE sales_hierarchy AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_manager,
        s_number_employees,
        s_floor_space,
        1 AS level
    FROM
        store
    WHERE
        s_closed_date_sk IS NULL
    UNION ALL
    SELECT
        s.s_store_sk,
        CONCAT(s.s_store_name, ' Sub-store'),
        s.s_manager,
        s.s_number_employees,
        s.s_floor_space,
        sh.level + 1
    FROM
        sales_hierarchy sh
    JOIN
        store s ON s.s_manager = sh.s_manager
    WHERE
        s.s_closed_date_sk IS NULL
),
sales_data AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_net_paid,
        ws.ws_net_profit,
        d.d_year,
        d.d_month_seq
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
)
SELECT
    sh.s_store_sk,
    sh.s_store_name,
    SUM(sd.ws_quantity) AS total_quantity_sold,
    SUM(sd.ws_net_paid) AS total_revenue,
    COUNT(DISTINCT cd.c_customer_sk) AS unique_customers,
    AVG(sh.level) AS average_store_level,
    STRING_AGG(CONCAT(cd.c_first_name, ' ', cd.c_last_name), ', ') AS customer_names
FROM
    sales_hierarchy sh
LEFT JOIN
    sales_data sd ON sh.s_store_sk = sd.ws_item_sk
LEFT JOIN
    customer_data cd ON sd.ws_order_number = cd.c_customer_sk
WHERE
    sh.s_number_employees > 0
GROUP BY
    sh.s_store_sk,
    sh.s_store_name
HAVING
    SUM(sd.ws_net_profit) > 0
ORDER BY
    total_revenue DESC
LIMIT 10;
