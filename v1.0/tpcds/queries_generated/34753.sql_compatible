
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ws_sold_date_sk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_sales_price) AS total_sales,
        cs_sold_date_sk
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk, cs_sold_date_sk
),
top_sales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_sales,
        DENSE_RANK() OVER (ORDER BY sd.total_sales DESC) AS sales_rank
    FROM 
        sales_data sd
),
customer_sales AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        SUM(ss_net_paid) AS total_spent,
        COUNT(ss_ticket_number) AS purchase_count
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY 
        c.c_customer_sk
),
customer_ranked AS (
    SELECT 
        customer_id,
        total_spent,
        purchase_count,
        DENSE_RANK() OVER (ORDER BY total_spent DESC) AS customer_rank
    FROM 
        customer_sales
)
SELECT
    c.c_first_name,
    c.c_last_name,
    ts.total_sales,
    tr.customer_rank,
    CASE
        WHEN ts.total_sales IS NULL THEN 'No Sales'
        ELSE 'Has Sales'
    END AS sales_status,
    COALESCE(d.d_date, 'Unknown Date') AS sales_date
FROM 
    top_sales ts
FULL OUTER JOIN 
    customer_ranked tr ON ts.ws_item_sk = tr.customer_id
LEFT JOIN 
    date_dim d ON ts.ws_sold_date_sk = d.d_date_sk
JOIN 
    customer c ON tr.customer_id = c.c_customer_sk
WHERE 
    tr.purchase_count > 1
    AND (c.c_birth_country IS NULL OR c.c_birth_country <> 'USA')
ORDER BY 
    tr.customer_rank, ts.total_sales DESC;
