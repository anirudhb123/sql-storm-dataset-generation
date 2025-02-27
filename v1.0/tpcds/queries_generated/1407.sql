
WITH sales_summary AS (
    SELECT 
        ws.web_site_id, 
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_ship_tax) AS avg_order_value,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status = 'M'
        AND cd.cd_purchase_estimate BETWEEN 1000 AND 5000
    GROUP BY 
        ws.web_site_id
),
top_sales AS (
    SELECT 
        web_site_id, 
        total_net_profit, 
        total_orders, 
        avg_order_value
    FROM 
        sales_summary
    WHERE 
        rank <= 5
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        c.c_email_address,
        COALESCE(cd.cd_credit_rating, 'Unknown') AS credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
returns_summary AS (
    SELECT 
        sr.store_sk, 
        COUNT(sr.sr_ticket_number) AS total_returns, 
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount
    FROM 
        store_returns sr
    GROUP BY 
        sr.store_sk
)
SELECT 
    tsi.web_site_id,
    c.first_name,
    c.last_name,
    c.email_address,
    ts.total_net_profit,
    ts.total_orders,
    ts.avg_order_value,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount
FROM 
    top_sales ts
JOIN 
    customer_info c ON c.c_customer_sk = (SELECT MIN(c.c_customer_sk) 
                                           FROM customer c 
                                           WHERE c.c_current_hdemo_sk IS NOT NULL)
LEFT JOIN 
    returns_summary rs ON rs.store_sk = (SELECT MIN(s.s_store_sk) FROM store s)
WHERE 
    c.last_name IS NOT NULL
ORDER BY 
    ts.total_net_profit DESC;
