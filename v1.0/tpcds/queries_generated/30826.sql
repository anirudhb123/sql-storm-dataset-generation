
WITH RECURSIVE sales_summary AS (
    SELECT 
        s_store_sk,
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        s_store_sk, ss_item_sk
),
top_sales AS (
    SELECT 
        s.store_id, 
        item.i_item_id, 
        item.i_product_name, 
        summary.total_quantity, 
        summary.total_sales
    FROM 
        (SELECT 
            s_store_sk, 
            MAX(total_sales) AS max_sales
        FROM 
            sales_summary
        GROUP BY 
            s_store_sk) AS max_sales_by_store
    JOIN 
        sales_summary summary ON summary.s_store_sk = max_sales_by_store.s_store_sk 
            AND summary.total_sales = max_sales_by_store.max_sales
    JOIN 
        store s ON s.s_store_sk = summary.s_store_sk
    JOIN 
        item ON item.i_item_sk = summary.ss_item_sk
),
customer_return_counts AS (
    SELECT 
        sr_customer_sk,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
)
SELECT 
    top_sales.store_id,
    top_sales.i_item_id,
    top_sales.i_product_name,
    top_sales.total_quantity,
    top_sales.total_sales,
    COALESCE(rc.return_count, 0) AS return_count,
    CASE 
        WHEN COALESCE(rc.return_count, 0) > 10 THEN 'High Return'
        WHEN COALESCE(rc.return_count, 0) BETWEEN 5 AND 10 THEN 'Moderate Return'
        ELSE 'Low Return'
    END AS return_category
FROM 
    top_sales 
LEFT JOIN 
    customer_return_counts rc ON rc.sr_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales) 
ORDER BY 
    top_sales.total_sales DESC
LIMIT 
    100;
