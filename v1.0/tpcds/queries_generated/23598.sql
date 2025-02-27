
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws.ws_order_number,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws.ws_net_profit DESC) AS profit_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > (
            SELECT 
                AVG(ws_inner.ws_sales_price)
            FROM 
                web_sales ws_inner
            WHERE 
                ws_inner.ws_sold_date_sk BETWEEN 2000000 AND 2001000
        )
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        CASE 
            WHEN cd.cd_marital_status IS NULL THEN 'Unknown'
            ELSE cd.cd_marital_status
        END AS marital_status,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT 
        rs.web_site_id,
        SUM(rs.ws_net_profit) AS total_profit,
        COUNT(rs.ws_order_number) AS total_orders,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM 
        ranked_sales rs
    LEFT JOIN 
        customer_info c ON c.total_customers > 0
    GROUP BY 
        rs.web_site_id
)
SELECT 
    ss.web_site_id,
    ss.total_profit,
    ss.total_orders,
    ss.unique_customers,
    CASE 
        WHEN ss.unique_customers = 0 THEN NULL
        ELSE ROUND(ss.total_profit / ss.unique_customers, 2)
    END AS avg_profit_per_customer
FROM 
    sales_summary ss
WHERE 
    ss.total_profit > (
        SELECT 
            AVG(total_profit)
        FROM (
            SELECT 
                rs.web_site_id,
                SUM(rs.ws_net_profit) AS total_profit
            FROM 
                ranked_sales rs
            GROUP BY 
                rs.web_site_id
        ) AS avg_profit
    )
ORDER BY 
    ss.total_profit DESC
LIMIT 10
OFFSET 5
UNION ALL
SELECT 
    DISTINCT c.c_customer_id AS web_site_id,
    0 AS total_profit,
    0 AS total_orders,
    0 AS unique_customers,
    NULL AS avg_profit_per_customer
FROM 
    customer c
WHERE 
    c.c_preferred_cust_flag IS NULL
ORDER BY 
    web_site_id;
