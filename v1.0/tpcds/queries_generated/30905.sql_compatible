
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s_store_sk,
        c_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        COUNT(ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY s_store_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        store_sales 
    LEFT JOIN 
        web_sales ON ss_item_sk = ws_item_sk AND ss_ticket_number = ws_order_number
    LEFT JOIN 
        customer ON ss_customer_sk = c_customer_sk
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
    GROUP BY 
        s_store_sk, c_customer_sk
),
FilteredSales AS (
    SELECT 
        s_store_sk, 
        SUM(total_profit) AS total_profit,
        SUM(order_count) AS total_orders
    FROM 
        SalesCTE
    WHERE 
        profit_rank <= 10
    GROUP BY 
        s_store_sk
)
SELECT 
    sm.sm_type,
    fs.total_profit,
    fs.total_orders,
    COALESCE(ROUND(fs.total_profit / NULLIF(fs.total_orders, 0), 2), 0) AS avg_profit_per_order
FROM 
    FilteredSales fs
JOIN 
    store s ON fs.s_store_sk = s.s_store_sk
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT MIN(ss.sm_ship_mode_sk) FROM store_sales ss WHERE ss.ss_store_sk = fs.s_store_sk)
ORDER BY 
    fs.total_profit DESC;
