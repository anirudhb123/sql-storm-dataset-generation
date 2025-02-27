
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        s.ss_sold_date_sk,
        SUM(s.ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(s.ss_net_paid) DESC) AS rnk
    FROM 
        customer c
    JOIN 
        store_sales s ON c.c_customer_sk = s.ss_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, s.ss_sold_date_sk
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
    HAVING 
        SUM(ws.ws_quantity) > 1000
),
customer_returns AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(*) AS returns_count,
        SUM(sr_net_loss) AS total_loss
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
)
SELECT 
    ch.c_first_name,
    ch.c_last_name,
    sh.total_sales,
    pi.i_item_id,
    pi.total_quantity_sold,
    cr.returns_count,
    cr.total_loss
FROM 
    sales_hierarchy sh
LEFT JOIN 
    popular_items pi ON sh.total_sales > 5000
LEFT JOIN 
    customer_returns cr ON sh.c_customer_sk = cr.sr_returning_customer_sk 
WHERE 
    sh.rnk = 1
ORDER BY 
    sh.total_sales DESC;
