
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND ws_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        ws_item_sk
    UNION ALL
    SELECT 
        cs_item_sk, 
        SUM(cs_net_paid) AS total_sales,
        COUNT(DISTINCT cs_order_number) AS order_count,
        DENSE_RANK() OVER (ORDER BY SUM(cs_net_paid) DESC) AS sales_rank
    FROM 
        catalog_sales 
    WHERE 
        cs_sold_date_sk >= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01')
        AND cs_sold_date_sk <= (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
    GROUP BY 
        cs_item_sk
    HAVING 
        SUM(cs_net_paid) > 1000
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(SCTE.total_sales, 0) AS total_web_sales,
    COALESCE(CSTE.total_sales,0) AS total_catalog_sales,
    (COALESCE(SCTE.order_count, 0) + COALESCE(CSTE.order_count, 0)) AS total_orders,
    (COALESCE(SCTE.total_sales, 0) + COALESCE(CSTE.total_sales, 0)) AS grand_total_sales
FROM 
    item i
LEFT JOIN (
    SELECT 
        ws_item_sk, 
        SUM(total_sales) AS total_sales,
        SUM(order_count) AS order_count
    FROM 
        SalesCTE 
    WHERE 
        sales_rank <= 10
    GROUP BY 
        ws_item_sk
) SCTE ON i.i_item_sk = SCTE.ws_item_sk
LEFT JOIN (
    SELECT 
        cs_item_sk, 
        SUM(total_sales) AS total_sales,
        SUM(order_count) AS order_count
    FROM 
        SalesCTE 
    WHERE 
        sales_rank <= 10
    GROUP BY 
        cs_item_sk
) CSTE ON i.i_item_sk = CSTE.cs_item_sk
WHERE 
    i.i_current_price IS NOT NULL
ORDER BY 
    grand_total_sales DESC 
LIMIT 20;
