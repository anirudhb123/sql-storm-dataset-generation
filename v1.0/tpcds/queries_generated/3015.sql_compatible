
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023)
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        r.total_orders,
        COALESCE((SELECT AVG(total_sales) 
                   FROM RankedSales rr 
                   WHERE rr.sales_rank <= 10), 0) AS avg_top_sales
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 50
),
ItemDetails AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        t.total_sales,
        t.total_orders,
        CASE 
            WHEN t.total_sales > t.avg_top_sales THEN 'Above Average'
            ELSE 'Below Average'
        END AS sales_performance
    FROM 
        TopItems t
    JOIN 
        item i ON t.ws_item_sk = i.i_item_sk
)
SELECT 
    id.i_product_name,
    id.total_sales,
    id.total_orders,
    id.sales_performance,
    CASE 
        WHEN id.total_sales IS NULL THEN 'Sales Data Not Available'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM 
    ItemDetails id
LEFT JOIN 
    store s ON s.s_store_sk = (SELECT ss.ss_store_sk 
                                FROM store_sales ss 
                                WHERE ss.ss_item_sk = id.ws_item_sk 
                                ORDER BY ss.ss_sold_date_sk DESC LIMIT 1)
WHERE 
    id.total_orders > 5
ORDER BY 
    id.total_sales DESC;
