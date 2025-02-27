
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank,
        SUM(ws_net_profit) OVER (PARTITION BY ws.web_site_sk) AS total_net_profit,
        SUM(ws_quantity) OVER (PARTITION BY ws.web_site_sk) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim)
), 
RelevantItems AS (
    SELECT 
        item.i_item_sk,
        item.i_product_name,
        MAX(item.i_current_price) AS max_price
    FROM 
        item
    JOIN 
        RankedSales rs ON rs.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_sk, item.i_product_name
), 
SalesAnalysis AS (
    SELECT 
        r.web_site_sk,
        r.ws_item_sk,
        r.quant_sold,
        CASE 
            WHEN r.total_net_profit > 1000 THEN 'High Profit'
            WHEN r.total_net_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit'
        END AS profit_category,
        CONCAT('Site: ', w.w_warehouse_name, ' | Quantity: ', CAST(r.total_quantity AS VARCHAR)) AS sales_info
    FROM 
        RankedSales r
    LEFT JOIN 
        warehouse w ON r.web_site_sk = w.w_warehouse_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    sa.profit_category,
    COUNT(sa.ws_item_sk) AS count_items,
    AVG(ri.max_price) AS avg_max_price,
    SUM(sa.quant_sold) AS total_sold,
    MAX(sa.sales_info) AS sales_summary
FROM 
    SalesAnalysis sa
JOIN 
    RelevantItems ri ON sa.ws_item_sk = ri.i_item_sk
GROUP BY 
    sa.profit_category
ORDER BY 
    total_sold DESC;
