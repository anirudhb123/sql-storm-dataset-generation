
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name, c.c_customer_sk
    HAVING 
        SUM(ss.ss_net_paid) > 1000
    
    UNION ALL
    
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.c_customer_sk,
        (sh.total_sales + SUM(ss.ss_net_paid)) AS total_sales
    FROM 
        sales_hierarchy sh
    JOIN 
        customer c ON sh.c_customer_sk = c.c_customer_sk
    JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk > (SELECT MAX(ds.d_date_sk) FROM date_dim ds WHERE ds.d_year = 2023)
    GROUP BY 
        c.c_first_name, c.c_last_name, c.c_customer_sk, sh.total_sales
),
ranked_sales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        sales_hierarchy
),
top_customers AS (
    SELECT 
        c.c_first_name,
        c.c_last_name,
        c.c_customer_sk,
        SUM(ss.ss_net_paid) AS total_sales
    FROM 
        customer c
    LEFT JOIN
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_first_name, c.c_last_name, c.c_customer_sk
    HAVING 
        SUM(ss.ss_net_paid) IS NOT NULL AND SUM(ss.ss_net_paid) > 5000
),
promotions_with_max_sales AS (
    SELECT 
        p.p_promo_name,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_name
    HAVING 
        SUM(ws.ws_ext_sales_price) = (SELECT MAX(total_sales) FROM (
            SELECT 
                SUM(ws_ext_sales_price) AS total_sales
            FROM 
                web_sales
            GROUP BY 
                ws_promo_sk
        ) AS max_sales)
)
SELECT 
    r.c_first_name,
    r.c_last_name,
    r.total_sales,
    tp.p_promo_name AS promo_name,
    tp.total_sales AS promo_sales
FROM 
    ranked_sales r
LEFT JOIN 
    promotions_with_max_sales tp ON tp.total_sales > 0
WHERE 
    r.sales_rank <= 10 AND 
    (r.total_sales > COALESCE(tp.total_sales, 0) * 2 OR tp.total_sales IS NULL)
ORDER BY 
    r.total_sales DESC;
