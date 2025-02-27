
WITH RECURSIVE SalesCTE (date_sk, total_sales, item_sk) AS (
    SELECT 
        ws_sold_date_sk, 
        SUM(ws_net_profit) AS total_sales, 
        ws_item_sk
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    
    UNION ALL
    
    SELECT 
        d.d_date_sk, 
        SUM(ws_net_profit) + c.total_sales, 
        c.item_sk
    FROM 
        SalesCTE c
    JOIN 
        date_dim d 
        ON d.d_date_sk = c.date_sk - 1
    GROUP BY 
        d.d_date_sk, c.item_sk
),
RankedSales AS (
    SELECT 
        s.date_sk, 
        s.total_sales, 
        i.i_item_id,
        RANK() OVER (PARTITION BY i.i_item_id ORDER BY s.total_sales DESC) as sales_rank
    FROM 
        SalesCTE s
    JOIN 
        item i ON s.item_sk = i.i_item_sk
)
SELECT 
    i.i_item_id,
    COALESCE(rs.total_sales, 0) as sales_amount,
    COUNT(sm.sm_ship_mode_sk) as available_ship_modes,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Selling'
        ELSE 'Regular'
    END as sales_category
FROM 
    item i
LEFT JOIN 
    RankedSales rs ON i.i_item_sk = rs.item_sk AND rs.sales_rank = 1
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk IN (
        SELECT DISTINCT ws_ship_mode_sk 
        FROM web_sales 
        WHERE ws_item_sk = i.i_item_sk
    )
GROUP BY 
    i.i_item_id, rs.total_sales, rs.sales_rank
ORDER BY 
    sales_amount DESC
LIMIT 10;
