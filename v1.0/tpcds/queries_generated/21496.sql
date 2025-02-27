
WITH RECURSIVE customer_sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
top_customers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_profit,
        DENSE_RANK() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        customer_sales cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_profit IS NOT NULL
),
promotions_with_sales AS (
    SELECT 
        p.p_promo_sk,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        COUNT(ws.ws_order_number) AS sales_count
    FROM 
        promotion p
    LEFT JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
),
high_discount_promotions AS (
    SELECT 
        p.p_promo_sk,
        p.p_promo_name,
        p.p_start_date_sk,
        p.p_end_date_sk,
        pd.total_discount
    FROM 
        promotion p
    JOIN 
        promotions_with_sales pd ON p.p_promo_sk = pd.p_promo_sk
    WHERE 
        pd.total_discount > (
            SELECT AVG(total_discount) 
            FROM promotions_with_sales
        )
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    hdp.p_promo_name,
    hdp.total_discount,
    tc.total_profit
FROM 
    top_customers tc
JOIN 
    high_discount_promotions hdp ON tc.rank <= 10
LEFT JOIN 
    store_sales ss ON ss.ss_customer_sk = tc.c_customer_sk
WHERE 
    (hdp.total_discount IS NOT NULL OR hdp.total_discount IS NULL)
    AND EXISTS (
        SELECT 1 
        FROM web_returns wr 
        WHERE wr.wr_returning_customer_sk = tc.c_customer_sk 
        AND wr.wr_return_qty > 0
    )
ORDER BY 
    tc.total_profit DESC, hdp.total_discount DESC
FETCH FIRST 10 ROWS ONLY;
