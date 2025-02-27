
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM web_sales ws
    WHERE ws.ws_sales_price > (
        SELECT AVG(ws2.ws_sales_price) 
        FROM web_sales ws2 
        WHERE ws2.ws_ship_date_sk IS NOT NULL
    )
),
average_returns AS (
    SELECT 
        cr.refunded_customer_sk,
        AVG(cr.cr_return_amount) AS avg_return_amount
    FROM catalog_returns cr
    WHERE cr.return_quantity > 0
    GROUP BY cr.refunded_customer_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_preferred_cust_flag,
        COALESCE(cd.cd_gender, 'N/A') AS gender,
        COALESCE(hd.hd_buy_potential, 'Unknown') AS buy_potential
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
)
SELECT 
    ci.c_customer_sk,
    ci.gender,
    ci.buy_potential,
    COUNT(DISTINCT rs.web_site_sk) AS site_count,
    AVG(ar.avg_return_amount) AS average_return
FROM customer_info ci
LEFT JOIN ranked_sales rs ON ci.c_customer_sk = rs.web_site_sk
LEFT JOIN average_returns ar ON ci.c_customer_sk = ar.refunded_customer_sk
WHERE 
    ci.c_preferred_cust_flag = 'Y' 
    AND (ar.avg_return_amount IS NULL OR ar.avg_return_amount < (
        SELECT AVG(avg_return_amount) FROM average_returns WHERE avg_return_amount IS NOT NULL
    ))
GROUP BY ci.c_customer_sk, ci.gender, ci.buy_potential
HAVING 
    COUNT(DISTINCT rs.web_site_sk) > 1 
    OR ci.gender = 'F'
ORDER BY ci.c_customer_sk DESC
LIMIT 20;
