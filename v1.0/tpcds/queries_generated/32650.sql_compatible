
WITH RECURSIVE sales_data AS (
    SELECT 
        ss_sold_date_sk, 
        ss_item_sk, 
        SUM(ss_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_sales_price) DESC) AS rank
    FROM 
        store_sales
    WHERE 
        ss_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ss_sold_date_sk, 
        ss_item_sk
),
top_sales AS (
    SELECT 
        sd.ss_item_sk,
        sd.total_sales,
        i.i_item_desc,
        ROW_NUMBER() OVER (ORDER BY sd.total_sales DESC) AS top_rank
    FROM 
        sales_data sd
    JOIN 
        item i ON sd.ss_item_sk = i.i_item_sk
    WHERE 
        sd.rank <= 5
    ORDER BY 
        sd.total_sales DESC
),
customer_counts AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS catalog_orders,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS web_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    tc.i_item_desc,
    tc.total_sales,
    cc.c_customer_id,
    cc.catalog_orders,
    cc.web_orders,
    cc.store_orders,
    COALESCE(tc.total_sales, 0) AS total_sales_for_customer
FROM 
    top_sales tc
FULL OUTER JOIN 
    customer_counts cc ON tc.ss_item_sk = cc.c_customer_id
WHERE 
    (cc.catalog_orders > 0 OR cc.web_orders > 0 OR cc.store_orders > 0)
ORDER BY 
    total_sales_for_customer DESC;
