
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_ship_date_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS rn
    FROM 
        web_sales
    WHERE 
        ws_ship_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
        AND ws_quantity BETWEEN 1 AND 100
),

ReturnCTE AS (
    SELECT 
        wr_item_sk,
        wr_order_number,
        COUNT(*) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk, wr_order_number
),

CombinedSales AS (
    SELECT 
        s.ws_item_sk,
        SUM(s.ws_quantity) AS total_quantity,
        COALESCE(r.return_count, 0) AS return_count,
        SUM(s.ws_quantity) - COALESCE(r.return_count, 0) AS net_sales
    FROM 
        SalesCTE s
    LEFT JOIN 
        ReturnCTE r ON s.ws_item_sk = r.wr_item_sk AND s.ws_order_number = r.wr_order_number
    GROUP BY 
        s.ws_item_sk, r.return_count
)

SELECT 
    i.i_item_id,
    i.i_product_name,
    cs.sold_total,
    ca.city,
    CASE 
        WHEN i.i_current_price IS NULL THEN 'Price Unavailable'
        ELSE CONCAT('Current Price: $', i.i_current_price)
    END AS price_info,
    DENSE_RANK() OVER (ORDER BY total_quantity DESC) AS sales_rank
FROM 
    item i
JOIN 
    (
        SELECT 
            ws_item_sk,
            SUM(ws_net_paid) AS sold_total
        FROM 
            web_sales
        WHERE 
            ws_sales_price IS NOT NULL
        GROUP BY 
            ws_item_sk
    ) cs ON i.i_item_sk = cs.ws_item_sk
JOIN 
    customer_address ca ON i.i_item_sk = ca.ca_address_sk -- Play on types here
WHERE 
    i.i_current_price > (SELECT AVG(i_current_price) FROM item) 
    AND exists (
        SELECT 1 
        FROM date_dim d
        WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim)
        AND d.d_date_sk = (SELECT MAX(date_dim.d_date_sk) FROM date_dim)
    )
ORDER BY 
    sales_rank, i_product_name 
FETCH FIRST 100 ROWS ONLY;
