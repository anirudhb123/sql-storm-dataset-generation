
WITH RECURSIVE sales_data AS (
    SELECT 
        ws.web_site_sk, 
        ws.web_site_id, 
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS rank
    FROM 
        web_sales ws 
    JOIN 
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT CASE WHEN cd_income_band_sk IS NOT NULL THEN cd_income_band_sk END) AS distinct_income_bands
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name
), 
return_stats AS (
    SELECT 
        sr_store_sk,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        SUM(sr_return_quantity) AS returned_quantity
    FROM 
        store_returns
    GROUP BY 
        sr_store_sk
)
SELECT 
    cs.c_customer_sk, 
    cs.c_first_name,
    sd.total_quantity,
    sd.total_sales,
    rs.total_returns,
    rs.total_returned_amount,
    rs.returned_quantity
FROM 
    customer_summary cs
JOIN 
    sales_data sd ON cs.total_orders = sd.rank
LEFT JOIN 
    return_stats rs ON rs.sr_store_sk = (SELECT s_store_sk FROM store WHERE s_store_id = (SELECT min(s_store_id) FROM store))
WHERE 
    cs.total_spent > (
        SELECT 
            AVG(total_spent) 
        FROM 
            customer_summary 
        WHERE 
            total_orders > 1
    ) 
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
