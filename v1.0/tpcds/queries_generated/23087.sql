
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    LEFT JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 0 AND 
        (ws.ws_net_paid > 0 OR ws.ws_net_paid_inc_tax IS NOT NULL)
    GROUP BY 
        ws.ws_sold_date_sk, ws.ws_item_sk
),
TopSales AS (
    SELECT 
        r.ws_sold_date_sk, 
        r.ws_item_sk, 
        r.total_quantity,
        r.total_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
),
Details AS (
    SELECT 
        ts.ws_sold_date_sk,
        ts.ws_item_sk,
        ts.total_quantity,
        ts.total_sales,
        CASE 
            WHEN ts.total_sales > 500 THEN 'High'
            WHEN ts.total_sales BETWEEN 200 AND 500 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        COALESCE(i.i_item_desc, 'Unknown Item') AS item_description,
        COALESCE(s.s_store_name, 'Unknown Store') AS store_name
    FROM 
        TopSales ts
    LEFT JOIN 
        item i ON ts.ws_item_sk = i.i_item_sk
    LEFT JOIN 
        store s ON (s.s_store_sk = (SELECT MIN(ss.s_store_sk) FROM store_sales ss WHERE ss.ss_item_sk = ts.ws_item_sk) 
                      OR s.s_store_sk IS NULL)
)
SELECT 
    d.ws_sold_date_sk,
    d.item_description,
    d.total_quantity,
    d.total_sales,
    d.sales_category,
    d.store_name,
    ROW_NUMBER() OVER (PARTITION BY d.sales_category ORDER BY d.total_sales DESC) AS category_rank
FROM 
    Details d
WHERE 
    (d.total_quantity IS NULL OR d.total_quantity > 0) AND 
    (d.store_name IS NOT NULL OR d.ws_sold_date_sk > 2000000)
ORDER BY 
    d.sales_category, d.total_sales DESC;
