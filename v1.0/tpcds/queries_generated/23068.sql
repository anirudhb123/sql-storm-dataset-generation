
WITH ranked_sales AS (
    SELECT 
        ws.web_site_id,
        ws_sold_date_sk,
        ws.ship_mode_sk,
        SUM(ws.net_profit) OVER (PARTITION BY ws.web_site_id ORDER BY ws_sold_date_sk DESC) AS cumulative_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        web_site we ON ws.web_site_sk = we.web_site_sk
    WHERE 
        ws_sold_date_sk BETWEEN 1 AND 365 AND 
        ws.ship_mode_sk IN (
            SELECT 
                sm_ship_mode_sk 
            FROM 
                ship_mode 
            WHERE 
                sm_type LIKE 'Air%'
        )
    GROUP BY 
        ws.web_site_id, ws_sold_date_sk, ws.ship_mode_sk
),
customer_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_preferred_cust_flag,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        CASE WHEN c.c_birth_month IS NULL THEN 'N/A' ELSE c.c_birth_month END AS birth_month
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, c.c_preferred_cust_flag, c.c_birth_month
),
return_analysis AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_ticket_number) AS total_returns,
        SUM(sr_return_quantity) AS total_returned_quantity,
        AVG(sr_return_amt) AS avg_return_amount
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_moy BETWEEN 1 AND 6)
    GROUP BY 
        sr_item_sk
)
SELECT 
    cs.c_customer_id,
    cs.total_spent,
    cs.order_count,
    ra.total_returns,
    ra.total_returned_quantity,
    ra.avg_return_amount,
    rs.cumulative_profit,
    rs.profit_rank
FROM 
    customer_sales cs
LEFT JOIN 
    return_analysis ra ON cs.total_spent > 1000 AND ra.total_returns > 0
LEFT JOIN 
    ranked_sales rs ON cs.c_customer_id = rs.web_site_id
WHERE 
    (ca_state IS NULL OR ca_state <> 'XX')
    AND cs.order_count > 1
ORDER BY 
    cs.total_spent DESC, ra.total_returned_quantity DESC
FETCH FIRST 10 ROWS ONLY;
