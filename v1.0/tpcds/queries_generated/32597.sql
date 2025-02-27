
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        (ws.ws_quantity * ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022)
        AND ws.ws_sold_date_sk <= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
),
AggregatedSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.total_sales) AS total_sales_amount,
        COUNT(s.ws_order_number) AS order_count
    FROM 
        SalesCTE s
    WHERE 
        s.rn = 1
    GROUP BY 
        s.ws_item_sk
),
HighValueItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(as.total_sales_amount, 0) AS total_sales_amount
    FROM 
        item i
    LEFT JOIN 
        AggregatedSales as ON i.i_item_sk = as.ws_item_sk
    WHERE 
        i.i_current_price > (
            SELECT AVG(i2.i_current_price)
            FROM item i2 
            WHERE i2.i_rec_start_date <= CURRENT_DATE
        )
)
SELECT 
    hvi.i_item_id,
    hvi.i_item_desc,
    hvi.total_sales_amount,
    CASE 
        WHEN hvi.total_sales_amount > 10000 THEN 'High'
        WHEN hvi.total_sales_amount BETWEEN 5000 AND 10000 THEN 'Medium'
        ELSE 'Low'
    END AS sales_category
FROM 
    HighValueItems hvi
WHERE 
    hvi.total_sales_amount > 0
ORDER BY 
    hvi.total_sales_amount DESC
LIMIT 10;
