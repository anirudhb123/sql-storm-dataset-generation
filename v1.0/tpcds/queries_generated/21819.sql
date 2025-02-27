
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY ws_sales_price DESC) AS rank,
        DENSE_RANK() OVER (ORDER BY ws_sales_price) AS dense_rank,
        COUNT(ws_order_number) OVER (PARTITION BY ws.web_site_id) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws_sales_price > (
            SELECT AVG(ws_inner.ws_sales_price) 
            FROM web_sales ws_inner
            WHERE ws_inner.ws_web_site_sk = ws.ws_web_site_sk
        )
),
ReturnFactors AS (
    SELECT 
        cr_returning_customer_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT cr_order_number) AS distinct_return_orders
    FROM 
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    COALESCE(rs.web_site_id, 'UNKNOWN') AS web_site,
    COUNT(DISTINCT s.ss_ticket_number) AS total_store_sales,
    SUM(s.ss_net_profit) AS total_store_profit,
    SUM(CASE 
            WHEN rs.rank = 1 THEN rs.ws_sales_price 
            ELSE 0 
        END) AS highest_price_sales,
    SUM(CASE 
            WHEN rf.total_returns IS NULL THEN 0 
            ELSE rf.total_returns 
        END) AS total_returns,
    SUM(CASE 
            WHEN rf.total_return_amount IS NULL THEN 0 
            ELSE rf.total_return_amount 
        END) AS total_return_amount
FROM 
    customer c
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
LEFT JOIN 
    store_sales s ON c.c_customer_sk = s.ss_customer_sk 
LEFT JOIN 
    ReturnFactors rf ON c.c_customer_sk = rf.cr_returning_customer_sk
WHERE 
    (c.c_birth_year BETWEEN 1980 AND 1995 AND c.c_preferred_cust_flag = 'Y')
    OR (c.c_birth_year IS NULL AND c.c_last_review_date_sk IS NOT NULL)
GROUP BY 
    c.c_customer_id, c.c_first_name, c.c_last_name, rs.web_site_id
ORDER BY 
    total_store_profit DESC, total_store_sales DESC;
