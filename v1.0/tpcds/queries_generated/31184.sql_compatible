
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_sales_price * ws.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY ws.ws_order_number

    UNION ALL 

    SELECT 
        ws2.ws_order_number,
        SUM(ws2.ws_sales_price * ws2.ws_quantity) + s.total_sales AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ws2.ws_sales_price * ws2.ws_quantity) DESC) AS sales_rank
    FROM web_sales ws2
    JOIN SalesCTE s ON ws2.ws_order_number = s.ws_order_number
    JOIN customer c2 ON ws2.ws_bill_customer_sk = c2.c_customer_sk
    WHERE c2.c_birth_month = 12
    GROUP BY ws2.ws_order_number, s.total_sales
),

FilteredSales AS (
    SELECT 
        ss_ticket_number,
        SUM(ss_ext_sales_price) AS total_store_sales,
        COUNT(DISTINCT ss_item_sk) AS unique_items_sold
    FROM store_sales
    WHERE ss_sold_date_sk > 2450000
    GROUP BY ss_ticket_number
),

FinalResults AS (
    SELECT 
        sct.ws_order_number,
        fs.total_store_sales,
        fs.unique_items_sold,
        sct.total_sales AS web_total_sales
    FROM SalesCTE sct
    LEFT JOIN FilteredSales fs ON sct.ws_order_number = fs.ss_ticket_number
)

SELECT 
    fr.ws_order_number,
    COALESCE(fr.total_store_sales, 0) AS total_store_sales,
    COALESCE(fr.unique_items_sold, 0) AS unique_items_sold,
    fr.web_total_sales,
    CASE 
        WHEN fr.web_total_sales > COALESCE(fr.total_store_sales, 0) THEN 'Web Sales Greater'
        WHEN fr.web_total_sales < COALESCE(fr.total_store_sales, 0) THEN 'Store Sales Greater'
        ELSE 'Equal Sales'
    END AS sales_comparison
FROM FinalResults fr
ORDER BY fr.web_total_sales DESC, fr.total_store_sales ASC
LIMIT 100;
