
WITH customer_return_stats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_quantity) AS total_return_quantity,
        SUM(sr.return_amt) AS total_return_amount,
        SUM(sr.return_tax) AS total_return_tax,
        CASE 
            WHEN COUNT(DISTINCT sr.ticket_number) > 0 THEN SUM(sr.return_amt) / COUNT(DISTINCT sr.ticket_number)
            ELSE 0
        END AS avg_return_per_ticket
    FROM customer AS c
    LEFT JOIN store_returns AS sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY c.c_customer_sk
),
item_sales_stats AS (
    SELECT 
        ws.ws_item_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        SUM(ws.ws_coupon_amt) AS total_coupon_amount,
        MAX(ws.ws_sales_price) AS max_sales_price
    FROM web_sales AS ws
    GROUP BY ws.ws_item_sk
),
ranking AS (
    SELECT
        cs.i_item_sk, 
        DENSE_RANK() OVER (ORDER BY iss.total_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (ORDER BY iss.total_quantity_sold DESC) AS quantity_rank
    FROM item_sales_stats AS iss
    JOIN item AS cs ON iss.ws_item_sk = cs.i_item_sk
)
SELECT 
    ca.ca_address_id,
    cd.cd_gender,
    r.total_returns,
    r.total_return_quantity,
    r.avg_return_per_ticket,
    ss.total_sales,
    ss.total_quantity_sold,
    ss.total_sales_amount,
    ss.max_sales_price,
    CASE 
        WHEN ss.total_sales > 100 THEN 'High Volume'
        WHEN ss.total_sales BETWEEN 50 AND 100 THEN 'Moderate Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category,
    CASE 
        WHEN cd.cd_marital_status = 'S' AND r.total_returns > 5 THEN 'Single High Returns'
        WHEN cd.cd_marital_status = 'M' AND r.total_returns > 10 THEN 'Married High Returns'
        ELSE 'Other'
    END AS return_category,
    COALESCE(r.total_return_amount, 0) - COALESCE(ss.total_coupon_amount, 0) AS net_amount,
    '{}' || STRING_AGG(ws_ws_sales_price::TEXT, ',' ORDER BY ws_web_page_sk) AS web_sales_prices
FROM customer_address AS ca
JOIN customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN customer_return_stats AS r ON c.c_customer_sk = r.c_customer_sk
LEFT JOIN item_sales_stats AS ss ON c.c_customer_sk = ss.ws_bill_customer_sk
LEFT JOIN ranking AS rk ON ss.ws_item_sk = rk.i_item_sk
WHERE (cd.cd_gender = 'F' OR cd.cd_gender IS NULL)
AND (ca.ca_state = 'CA' OR ca.ca_state IS NULL)
AND (
    EXISTS (
        SELECT 1 
        FROM web_page AS wp 
        WHERE wp.wp_customer_sk = c.c_customer_sk
        AND wp.wp_creation_date_sk BETWEEN 20240101 AND 20241231
    ) 
    OR 
    NOT EXISTS (
        SELECT 1 
        FROM store_sales AS s 
        WHERE s.ss_customer_sk = c.c_customer_sk
    )
)
GROUP BY ca.ca_address_id, cd.cd_gender, r.total_returns, r.total_return_quantity, r.avg_return_per_ticket, ss.total_sales, ss.total_quantity_sold, ss.total_sales_amount, ss.max_sales_price, cd.cd_marital_status
ORDER BY ca.ca_address_id, r.total_return_quantity DESC
LIMIT 100;
