
WITH ranked_sales AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_ext_sales_price, 
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_ext_sales_price DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
), 
store_sales_summary AS (
    SELECT 
        ss_item_sk,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_ticket_number) AS total_transactions
    FROM 
        store_sales 
    WHERE 
        ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ss_item_sk
), 
failed_returns AS (
    SELECT 
        cr_item_sk, 
        SUM(cr_return_quantity) AS total_returned
    FROM 
        catalog_returns 
    WHERE 
        cr_return_amount < 0
    GROUP BY 
        cr_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(SUM(ws.ws_ext_sales_price), 0) AS web_sales_total,
    COALESCE(ss.total_store_sales, 0) AS store_sales_total,
    COALESCE(fr.total_returned, 0) AS total_failed_returns,
    rd.sales_rank AS top_rank
FROM 
    item i
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    store_sales_summary ss ON i.i_item_sk = ss.ss_item_sk
LEFT JOIN 
    failed_returns fr ON i.i_item_sk = fr.cr_item_sk
LEFT JOIN 
    ranked_sales rd ON i.i_item_sk = rd.ws_item_sk
WHERE 
    i.i_current_price > 10.00
GROUP BY 
    i.i_item_id, rd.sales_rank
HAVING 
    SUM(ws.ws_ext_sales_price) + COALESCE(ss.total_store_sales, 0) > 1000
ORDER BY 
    web_sales_total DESC, total_store_sales DESC;
