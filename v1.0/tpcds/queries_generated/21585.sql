
WITH ranked_sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank,
        SUM(ws.ws_sales_price) OVER (PARTITION BY c.c_customer_sk) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 10000 AND 20000
        AND c.c_current_cdemo_sk IS NOT NULL
)

SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    r.sales_rank,
    r.total_spent,
    CASE 
        WHEN r.sales_rank = 1 THEN 'Top Spender'
        ELSE 'Regular Spender'
    END AS spender_type
FROM 
    ranked_sales r
LEFT JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
WHERE 
    (cd.cd_gender = 'F' AND r.total_spent > 5000)
    OR (cd.cd_gender = 'M' AND r.total_spent > 3000)
    OR (cd.cd_gender IS NULL AND r.total_spent > 2000)
ORDER BY 
    r.total_spent DESC
LIMIT 10;

SELECT 
    r.c_customer_id,
    COUNT(DISTINCT wr.wr_order_number) AS return_count,
    r.total_spent AS total_spent
FROM 
    ranked_sales r
LEFT JOIN 
    web_returns wr ON r.c_customer_id = wr.wr_returning_customer_sk
GROUP BY 
    r.c_customer_id, r.total_spent
HAVING 
    return_count > 0
    AND total_spent - SUM(wr.wr_return_amt) != total_spent
ORDER BY 
    return_count DESC
INTERSECT
SELECT 
    r.c_customer_id,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    r.total_spent AS total_spent
FROM 
    ranked_sales r
LEFT JOIN 
    store_returns sr ON r.c_customer_id = sr.sr_customer_sk
GROUP BY 
    r.c_customer_id, r.total_spent
HAVING 
    store_return_count > 0
    AND total_spent - SUM(sr.sr_return_amt) IS NOT NULL
ORDER BY 
    store_return_count DESC;
