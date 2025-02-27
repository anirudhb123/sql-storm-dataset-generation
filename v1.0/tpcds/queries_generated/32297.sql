
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        s.s_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_quantity,
        SUM(s.ss_net_paid) AS total_net_paid
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        s.s_sold_date_sk, s.ss_item_sk
), CombinedSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        COALESCE(web.total_quantity, 0) AS web_quantity,
        COALESCE(store.total_quantity, 0) AS store_quantity,
        (COALESCE(web.total_net_paid, 0) + COALESCE(store.total_net_paid, 0)) AS total_net_sales
    FROM 
        item 
    LEFT JOIN 
        (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity, SUM(ws_net_paid) AS total_net_paid 
         FROM SalesCTE 
         GROUP BY ws_item_sk) AS web ON item.i_item_sk = web.ws_item_sk
    LEFT JOIN 
        (SELECT ss_item_sk, SUM(ss_quantity) AS total_quantity, SUM(ss_net_paid) AS total_net_paid 
         FROM store_sales 
         WHERE ss_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023) 
         GROUP BY ss_item_sk) AS store ON item.i_item_sk = store.ss_item_sk
), TotalSales AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_sales DESC) AS sales_rank,
        DENSE_RANK() OVER (PARTITION BY item.i_category_id ORDER BY total_net_sales DESC) AS category_rank
    FROM 
        CombinedSales
)
SELECT 
    ts.i_item_id,
    ts.i_product_name,
    ts.web_quantity,
    ts.store_quantity,
    ts.total_net_sales,
    ts.sales_rank,
    ts.category_rank
FROM 
    TotalSales ts
WHERE 
    ts.total_net_sales > 0
    AND COALESCE(ts.web_quantity, 0) + COALESCE(ts.store_quantity, 0) > 10
ORDER BY 
    ts.sales_rank, ts.category_rank;
