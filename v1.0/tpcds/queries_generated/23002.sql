
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank,
        MAX(dd.d_year) AS max_year
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    GROUP BY 
        ws.ws_item_sk
),
FilteredSales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        rs.total_quantity,
        rs.total_profit,
        CASE 
            WHEN rs.profit_rank = 1 THEN 'Highest'
            WHEN rs.profit_rank = 2 THEN 'Second Highest'
            ELSE 'Other'
        END AS rank_category
    FROM 
        RankedSales AS rs
    JOIN 
        item AS item ON rs.ws_item_sk = item.i_item_sk
    WHERE 
        rs.total_profit > (SELECT AVG(total_profit) FROM RankedSales) 
          AND item.i_current_price IS NOT NULL
)
SELECT 
    fa.item_id,
    fa.item_desc,
    fa.total_quantity,
    fa.total_profit,
    COALESCE(ib.ib_lower_bound, 0) AS lower_bound,
    COALESCE(ib.ib_upper_bound, 100000) AS upper_bound,
    (fa.total_profit * CASE WHEN fa.rank_category = 'Highest' THEN 1.1 ELSE 1 END) AS adjusted_profit,
    CASE 
        WHEN fa.total_profit IS NULL THEN 'Profit data unavailable'
        WHEN fa.total_profit < 1000 AND fa.rank_category = 'Highest' THEN 'Low profit for best item'
        ELSE 'All good'
    END AS profit_status
FROM 
    FilteredSales AS fa
LEFT JOIN 
    household_demographics AS hd ON fa.total_quantity = hd.hd_dep_count
LEFT JOIN 
    income_band AS ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE 
    fa.total_profit BETWEEN 
        (SELECT COALESCE(MIN(total_profit), 0) FROM FilteredSales)
    AND 
        (SELECT COALESCE(MAX(total_profit), 100000) FROM FilteredSales)
ORDER BY 
    fa.total_profit DESC NULLS LAST;
