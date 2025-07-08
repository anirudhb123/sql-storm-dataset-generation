
WITH sales_summary AS (
    SELECT
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_revenue,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY
        ws_bill_customer_sk
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        ca.ca_city,
        ca.ca_state,
        (SELECT ib_lower_bound FROM income_band WHERE ib_income_band_sk = hd.hd_income_band_sk) AS lower_income,
        (SELECT ib_upper_bound FROM income_band WHERE ib_income_band_sk = hd.hd_income_band_sk) AS upper_income
    FROM
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
),
ranked_sales AS (
    SELECT
        s.ws_bill_customer_sk,
        s.total_quantity,
        s.total_revenue,
        RANK() OVER (PARTITION BY s.ws_bill_customer_sk ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM
        sales_summary s
)
SELECT
    ci.c_customer_sk,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.ca_city,
    ci.ca_state,
    rs.total_quantity,
    rs.total_revenue,
    COALESCE(NULLIF(a.sm_carrier, ''), 'Unknown') AS carrier,
    CASE 
        WHEN rs.total_revenue > 1000 THEN 'High Value'
        WHEN rs.total_revenue BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_value,
    'Income Range: ' || ci.lower_income || ' - ' || ci.upper_income AS income_range
FROM
    customer_info ci
LEFT JOIN
    ranked_sales rs ON ci.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN
    ship_mode a ON rs.ws_bill_customer_sk = a.sm_ship_mode_sk
WHERE
    rs.revenue_rank = 1
ORDER BY
    ci.ca_state, ci.ca_city, rs.total_revenue DESC
LIMIT 100
OFFSET 0;
