
WITH sales_summary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
        (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) AND 
        (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.web_site_id
),
customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
return_summary AS (
    SELECT 
        cr_reason_sk,
        COUNT(*) AS total_returns,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr_reason_sk
)
SELECT 
    s.web_site_id,
    ss.total_net_profit,
    ss.total_orders,
    cs.total_orders AS customer_orders,
    cs.credit_rating,
    rs.total_returns,
    rs.total_return_amount,
    ss.avg_net_paid,
    CASE 
        WHEN ss.total_net_profit > 10000 THEN 'High'
        WHEN ss.total_net_profit > 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM 
    sales_summary ss
JOIN 
    customer_summary cs ON ss.web_site_id = (
        SELECT 
            ws.web_site_id
        FROM 
            web_sales ws
        WHERE 
            ws.ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales)
        LIMIT 1
    )
LEFT JOIN 
    return_summary rs ON rs.cr_reason_sk IN (
        SELECT 
            r.r_reason_sk 
        FROM 
            reason r
        WHERE 
            r.r_reason_desc IS NOT NULL
    )
WHERE 
    ss.rank <= 10
ORDER BY 
    ss.total_net_profit DESC;
