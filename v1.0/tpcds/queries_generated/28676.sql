
WITH customer_data AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        LENGTH(c.c_email_address) AS email_length,
        CHARINDEX('@', c.c_email_address) AS at_position,
        SUBSTRING(c.c_email_address, 1, CHARINDEX('@', c.c_email_address) - 1) AS email_username
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE cd.cd_gender = 'F'
),

address_analysis AS (
    SELECT
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_id) AS female_count,
        AVG(email_length) AS avg_email_length,
        MAX(email_length) AS max_email_length
    FROM customer_data c
    GROUP BY ca.ca_state
),

date_analysis AS (
    SELECT
        d.d_year,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers,
        SUM(CASE WHEN c.c_birth_day = 1 THEN 1 ELSE 0 END) AS births_on_first
    FROM date_dim d
    JOIN customer c ON d.d_date_sk = c.c_first_shipto_date_sk
    GROUP BY d.d_year
),

shipping_analysis AS (
    SELECT
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY sm.sm_type
)

SELECT
    a.ca_state,
    a.female_count,
    a.avg_email_length,
    a.max_email_length,
    d.unique_customers,
    d.births_on_first,
    s.sm_type,
    s.total_quantity,
    s.total_profit
FROM address_analysis a
JOIN date_analysis d ON 1=1
JOIN shipping_analysis s ON 1=1
ORDER BY a.ca_state, s.sm_type;
