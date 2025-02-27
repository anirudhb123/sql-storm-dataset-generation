
WITH ranked_sales AS (
    SELECT
        ws.web_site_sk,
        ws.net_paid,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.sold_date_sk DESC) AS rank_sales
    FROM
        web_sales ws
    WHERE
        ws.sold_date_sk > (SELECT MAX(d_date_sk) - 30 FROM date_dim)
),
customer_info AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        h.hd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY h.hd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS income_rank
    FROM
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics h ON c.c_current_hdemo_sk = h.hd_demo_sk
),
sales_summary AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.order_number) AS total_orders
    FROM
        web_sales ws
    GROUP BY
        ws.web_site_sk
)
SELECT 
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    ci.cd_marital_status,
    ci.cd_purchase_estimate,
    ss.total_net_paid,
    ss.total_orders,
    CASE 
        WHEN ci.hd_income_band_sk IS NULL THEN 'Unknown'
        ELSE CAST(ci.hd_income_band_sk AS varchar)
    END AS income_band,
    rs.net_paid AS last_sales_amount
FROM 
    customer_info ci
JOIN 
    sales_summary ss ON ci.c_customer_sk = ss.web_site_sk
LEFT JOIN 
    (SELECT * FROM ranked_sales WHERE rank_sales = 1) rs ON ss.web_site_sk = rs.web_site_sk
WHERE 
    (ci.income_rank <= 5 OR ci.cd_purchase_estimate IS NULL)
ORDER BY 
    ss.total_net_paid DESC
LIMIT 10;
