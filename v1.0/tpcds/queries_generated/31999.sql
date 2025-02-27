
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk

    UNION ALL

    SELECT 
        sd.ws_sold_date_sk,
        sd.ws_item_sk,
        sd.total_quantity + s.ws_quantity,
        sd.total_profit + s.ws_net_profit
    FROM 
        SalesData sd
    JOIN 
        web_sales s ON sd.ws_item_sk = s.ws_item_sk
    WHERE 
        sd.ws_sold_date_sk > s.ws_sold_date_sk
),
FilteredSales AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_profit
    FROM 
        SalesData sd
    WHERE 
        sd.total_profit > 1000
),
RankedSales AS (
    SELECT 
        fs.ws_item_sk,
        fs.total_quantity,
        fs.total_profit,
        RANK() OVER (ORDER BY fs.total_profit DESC) AS profit_rank
    FROM 
        FilteredSales fs
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    rs.total_quantity,
    rs.total_profit,
    rs.profit_rank,
    COALESCE(prom.p_promo_name, 'No Promotion') AS promotion_name
FROM 
    RankedSales rs
JOIN 
    item i ON rs.ws_item_sk = i.i_item_sk
LEFT JOIN 
    promotion prom ON i.i_item_sk = prom.p_item_sk AND prom.p_start_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_day='Y')
WHERE 
    rs.profit_rank <= 10
ORDER BY 
    rs.profit_rank;
