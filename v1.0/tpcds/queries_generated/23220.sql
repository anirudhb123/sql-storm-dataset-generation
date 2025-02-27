
WITH RankedSales AS (
    SELECT 
        sm.sm_ship_mode_id,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY sm.sm_ship_mode_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023 AND d_month_seq = 6
        )
    GROUP BY 
        sm.sm_ship_mode_id, ws.ws_sold_date_sk
),
TopSales AS (
    SELECT 
        r.sm_ship_mode_id,
        r.total_quantity,
        r.total_sales,
        r.sales_rank,
        ROW_NUMBER() OVER (PARTITION BY r.sm_ship_mode_id ORDER BY r.total_sales DESC) AS row_num
    FROM 
        RankedSales r
    WHERE 
        r.sales_rank <= 5
)
SELECT 
    t.sm_ship_mode_id,
    COALESCE(Total_Sales, 0) AS Adjusted_Total_Sales,
    CASE 
        WHEN t.total_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Recorded'
    END AS Sales_Status,
    STRING_AGG(t.sm_ship_mode_id, ', ') WITHIN GROUP (ORDER BY t.total_sales DESC) AS Combined_Ships
FROM 
    TopSales t
LEFT JOIN 
    warehouse w ON t.sm_ship_mode_id = w.w_warehouse_id
WHERE 
    t.row_num < 4 OR (t.row_num IS NULL AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk IS NOT NULL
    ))
GROUP BY 
    t.sm_ship_mode_id, t.total_sales
ORDER BY 
    Adjusted_Total_Sales DESC;

-- Checking NULL handling and bizarre aggregates
SELECT 
    c.c_customer_id,
    c.c_first_name,
    COUNT(DISTINCT CASE WHEN ws.ws_item_sk IS NOT NULL THEN ws.ws_order_number END) AS Orders_With_Products,
    SUM(ws.ws_net_profit) AS Total_Profit,
    MAX(NULLIF(ws.ws_ship_mode_sk, -1)) AS Non_Negative_Ship_Mode
FROM 
    customer c 
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM store_returns sr 
        WHERE sr.sr_customer_sk = c.c_customer_sk AND sr.sr_return_quantity > 0
    )
GROUP BY 
    c.c_customer_id, c.c_first_name
HAVING 
    SUM(ws.ws_net_profit) > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk)
ORDER BY 
    Orders_With_Products DESC;
