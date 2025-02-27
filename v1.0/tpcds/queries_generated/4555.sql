
WITH ranked_sales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND 
        ws.ws_quantity > 0
),
total_revenue AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
item_promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_item_sk,
        COUNT(p.p_promo_id) AS promo_count
    FROM 
        promotion p
    GROUP BY 
        p.p_promo_sk, p.p_item_sk
)
SELECT 
    ca.ca_city,
    SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales,
    COALESCE(SUM(tr.total_returns), 0) AS total_returns,
    ip.promo_count
FROM 
    ranked_sales rs
LEFT JOIN 
    total_revenue tr ON rs.ws_item_sk = tr.wr_item_sk
LEFT JOIN 
    item_promotions ip ON rs.ws_item_sk = ip.p_item_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = (
        SELECT c.c_current_addr_sk
        FROM customer c 
        WHERE c.c_customer_sk = rs.ws_bill_customer_sk
    )
WHERE 
    rs.rn = 1 -- only take the highest sales price per item
GROUP BY 
    ca.ca_city, ip.promo_count
ORDER BY 
    total_sales DESC
LIMIT 10;
