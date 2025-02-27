
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales ws
    INNER JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk 
                                FROM date_dim 
                                WHERE d_year = 2023 AND d_month_seq IN (10, 11))
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.full_name,
    ci.cd_gender,
    ci.cd_marital_status,
    rs.total_quantity,
    rs.total_sales,
    CASE 
        WHEN ci.cd_gender = 'M' AND ci.cd_purchase_estimate > 1000 THEN 'High Value Male'
        WHEN ci.cd_gender = 'F' AND ci.cd_purchase_estimate > 1000 THEN 'High Value Female'
        ELSE 'Other'
    END AS customer_segment,
    r.reason_desc
FROM 
    customer_info ci
LEFT JOIN 
    store_returns sr ON ci.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN 
    ranked_sales rs ON ci.c_customer_sk = rs.web_site_sk
WHERE 
    (ci.income_band IS NOT NULL OR ci.income_band = 0)
    AND rs.total_sales > 1000
    AND rs.sales_rank <= 10
ORDER BY 
    rs.total_sales DESC;
