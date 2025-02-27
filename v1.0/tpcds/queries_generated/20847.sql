
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sale_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid IS NOT NULL
),
agg_return_stats AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
warehouse_data AS (
    SELECT 
        w.w_warehouse_sk,
        MAX(w.w_warehouse_sq_ft) AS max_sq_ft,
        AVG(w.w_gmt_offset) AS avg_gmt_offset
    FROM 
        warehouse w
    GROUP BY 
        w.w_warehouse_sk
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT c.c_customer_id) AS total_customers,
    SUM(ws.ws_net_profit) AS total_profit,
    AVG(CASE WHEN ws.ws_net_paid > 0 THEN ws.ws_net_paid ELSE NULL END) AS avg_paid,
    SUM(COALESCE(rs.sale_rank, 0)) AS total_rank_from_sales,
    wg.max_sq_ft,
    wg.avg_gmt_offset,
    rb.total_return_amount
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    ranked_sales rs ON ws.ws_order_number = rs.ws_order_number AND rs.sale_rank <= 10
LEFT JOIN 
    agg_return_stats rb ON ws.ws_item_sk = rb.wr_item_sk
JOIN 
    warehouse_data wg ON ws.ws_warehouse_sk = wg.w_warehouse_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND ca.ca_city NOT IN (SELECT DISTINCT ca_city FROM customer_address WHERE ca_state = 'NY')
    AND (c.c_birth_year > 1980 OR (c.c_birth_year < 1970 AND c.c_preferred_cust_flag = 'Y'))
GROUP BY 
    ca.ca_city, wg.max_sq_ft, wg.avg_gmt_offset, rb.total_return_amount
HAVING 
    COUNT(DISTINCT c.c_customer_id) > 100
ORDER BY 
    total_profit DESC;
