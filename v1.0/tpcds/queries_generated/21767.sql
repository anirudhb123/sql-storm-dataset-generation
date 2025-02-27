
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ext_sales_price DESC) AS rn,
        CASE 
            WHEN ws.quantity > 5 THEN 'High Volume'
            WHEN ws.quantity BETWEEN 2 AND 5 THEN 'Medium Volume'
            ELSE 'Low Volume'
        END AS volume_category
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year >= 1980
)

SELECT 
    w.w_warehouse_name,
    COALESCE(SUM(s.ss_net_profit), 0) AS total_net_profit,
    COUNT(DISTINCT r.ws_order_number) AS unique_orders,
    SUM(CASE WHEN r.volume_category = 'High Volume' THEN r.sales_price ELSE 0 END) AS high_volume_sales,
    COUNT(CASE WHEN r.rn = 1 AND r.volume_category = 'Medium Volume' THEN 1 END) AS medium_sales_top_rank
FROM 
    ranked_sales r
LEFT JOIN 
    store_sales s ON r.ws_order_number = s.ss_order_number
JOIN 
    warehouse w ON s.ss_store_sk = w.w_warehouse_sk
WHERE 
    w.w_gmt_offset IS NOT NULL
GROUP BY 
    w.w_warehouse_name
HAVING 
    COUNT(DISTINCT r.ws_order_number) > 10
ORDER BY 
    total_net_profit DESC
LIMIT 5;

-- Overlap with store returns and peculiar NULL checks
SELECT 
    c.c_customer_id,
    COALESCE(SUM(sr_return_amt), 0) AS total_return_amt,
    COUNT(DISTINCT ss_ticket_number) AS return_tickets,
    STRING_AGG(DISTINCT r.r_reason_desc, ', ' ORDER BY r.r_reason_desc) AS return_reasons
FROM 
    store_returns sr
JOIN 
    reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN 
    store_sales ss ON sr.sr_item_sk = ss.ss_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN 
    customer c ON sr.sr_customer_sk = c.c_customer_sk
WHERE 
    sr_returned_date_sk IS NOT NULL
AND 
    (c.c_current_cdemo_sk IS NOT NULL OR c.c_current_hdemo_sk IS NULL)
GROUP BY 
    c.c_customer_id
HAVING 
    total_return_amt > 100.00
ORDER BY 
    total_return_amt DESC;
