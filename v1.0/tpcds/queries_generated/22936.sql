
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.net_profit DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.net_profit IS NOT NULL
        AND ws.net_profit > (
            SELECT AVG(net_profit)
            FROM web_sales 
            WHERE web_site_sk = ws.web_site_sk
        )
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M'
        OR (cd.cd_gender = 'F' AND cd.cd_credit_rating = 'Low')
),
inventory_summary AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
),
returns_summary AS (
    SELECT 
        sr_store_sk,
        SUM(sr_return_quantity) AS total_returns
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    r.web_site_sk,
    ci.c_first_name,
    ci.c_last_name,
    ISNULL(q.total_quantity, 0) AS total_inv,
    ISNULL(rs.total_returns, 0) AS total_returns,
    AVG(rs.net_profit) AS avg_net_profit
FROM 
    ranked_sales r
LEFT JOIN 
    inventory_summary q ON r.web_site_sk = q.warehouse_sk
LEFT JOIN 
    returns_summary rs ON r.web_site_sk = rs.sr_store_sk
JOIN 
    customer_info ci ON ci.c_customer_sk = r.web_site_sk
WHERE 
    (SELECT COUNT(*) FROM store WHERE s_store_sk = r.web_site_sk) = 1
GROUP BY 
    r.web_site_sk, ci.c_first_name, ci.c_last_name, q.total_quantity, rs.total_returns
HAVING 
    AVG(rs.net_profit) > 1000
ORDER BY 
    r.web_site_sk DESC, total_inv ASC
LIMIT 50;
