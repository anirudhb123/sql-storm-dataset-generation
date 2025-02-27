
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        CASE 
            WHEN SUM(ws.ws_net_paid) > 1000 THEN 'High Value'
            WHEN SUM(ws.ws_net_paid) BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS sales_category,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_id
),
filtered_sales AS (
    SELECT 
        ss.web_site_id, 
        ss.total_quantity, 
        ss.total_net_paid
    FROM 
        sales_summary ss
    WHERE 
        ss.sales_rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_demographics_sk,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY c.c_birth_year DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    fs.web_site_id,
    ci.c_first_name,
    ci.c_last_name,
    ci.cd_gender,
    fs.total_quantity,
    fs.total_net_paid,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM 
    filtered_sales fs
JOIN 
    customer_info ci ON ci.rn = 1
LEFT JOIN 
    returns_summary rs ON rs.wr_item_sk = fs.web_site_id
ORDER BY 
    fs.total_net_paid DESC, 
    fs.total_quantity ASC;
