
WITH RankedSales AS (
    SELECT 
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) as rn,
        SUM(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_item_sk) as total_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk > (
            SELECT MAX(dd.d_date_sk) 
            FROM date_dim dd 
            WHERE dd.d_year = 2023 AND dd.d_moy IN (5, 6)
        )
),
HighPerformers AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) as total_inventory,
        MAX(r.total_sales) as max_sales
    FROM 
        inventory inv
    LEFT JOIN 
        RankedSales r ON inv.inv_item_sk = r.ws_item_sk
    GROUP BY 
        inv.inv_item_sk
    HAVING 
        SUM(inv.inv_quantity_on_hand) > 100 AND 
        MAX(r.total_sales) IS NOT NULL
), 
FinalSales AS (
    SELECT 
        it.i_item_id, 
        it.i_item_desc, 
        hp.total_inventory,
        hp.max_sales,
        CASE 
            WHEN hp.max_sales >= 10000 THEN 'High'
            WHEN hp.max_sales BETWEEN 5000 AND 10000 THEN 'Medium'
            ELSE 'Low' 
        END as sales_category
    FROM 
        item it
    JOIN 
        HighPerformers hp ON it.i_item_sk = hp.inv_item_sk
),
ReturnedSales AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
)
SELECT 
    fs.i_item_id,
    fs.i_item_desc,
    fs.total_inventory,
    fs.max_sales,
    fs.sales_category,
    COALESCE(rs.total_returns, 0) as total_returns,
    ROUND(((fs.max_sales - COALESCE(rs.total_returns, 0)) / NULLIF(fs.max_sales, 0)) * 100, 2) as return_ratio,
    CASE 
        WHEN fs.sales_category = 'High' AND COALESCE(rs.total_returns, 0) < 50 THEN 'Verified Top Performer'
        WHEN fs.sales_category = 'Low' AND COALESCE(rs.total_returns, 0) > 100 THEN 'Under Review'
        ELSE 'Standard Review'
    END as performance_status
FROM 
    FinalSales fs
LEFT JOIN 
    ReturnedSales rs ON fs.i_item_id = rs.wr_item_sk
ORDER BY 
    fs.sales_category DESC, fs.max_sales DESC;
