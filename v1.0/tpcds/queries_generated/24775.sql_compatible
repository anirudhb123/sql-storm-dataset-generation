
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL
        AND (c.c_birth_month BETWEEN 1 AND 6 OR c.c_current_cdemo_sk IS NULL)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        ranked.total_quantity, 
        ranked.total_net_profit
    FROM 
        item
    JOIN 
        RankedSales ranked ON item.i_item_sk = ranked.ws_item_sk
    WHERE 
        ranked.rn = 1
),
FilteredSales AS (
    SELECT 
        ts.i_item_id,
        ts.i_product_name,
        ts.total_quantity,
        ts.total_net_profit,
        DENSE_RANK() OVER (ORDER BY ts.total_net_profit DESC) AS sales_rank
    FROM 
        TopSales ts
    WHERE 
        ts.total_net_profit IS NOT NULL
        AND ts.total_quantity > 0
)
SELECT 
    fs.i_product_name,
    fs.sales_rank,
    COALESCE(ROUND(fs.total_net_profit / NULLIF(fs.total_quantity, 0), 2), 0) AS avg_net_profit_per_item
FROM 
    FilteredSales fs
WHERE 
    fs.sales_rank <= 10
ORDER BY 
    fs.sales_rank
UNION ALL
SELECT 
    'Total' AS i_product_name,
    NULL AS sales_rank,
    SUM(fs.avg_net_profit_per_item) AS avg_net_profit_per_item
FROM (
    SELECT 
        COALESCE(ROUND(total_net_profit / NULLIF(total_quantity, 0), 2), 0) AS avg_net_profit_per_item
    FROM 
        FilteredSales 
) fs_total
WHERE 
    fs_total.avg_net_profit_per_item IS NOT NULL;
