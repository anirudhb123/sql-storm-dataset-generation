
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS price_rank,
        COALESCE(NULLIF(SUM(ss.ss_quantity) OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 0), 1) AS cumulative_sales
    FROM 
        web_sales ws
    LEFT JOIN 
        store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        ws.ws_sales_price > 0
),
CustomerActivity AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_last_name
),
FilteredSales AS (
    SELECT 
        r.ws_order_number,
        r.ws_item_sk,
        r.ws_sales_price,
        r.cumulative_sales,
        ca.c_last_name,
        ca.total_orders,
        ca.total_profit
    FROM 
        RankedSales r
    JOIN 
        CustomerActivity ca ON r.ws_order_number IN (
            SELECT 
                ws.ws_order_number 
            FROM 
                web_sales ws 
            WHERE 
                ws.ws_item_sk = r.ws_item_sk 
                AND r.price_rank = 1 
                AND ws.ws_sales_price / NULLIF(r.cumulative_sales, 0) > 5
        )
    WHERE 
        r.cumulative_sales IS NOT NULL
)
SELECT 
    DISTINCT f.ws_order_number,
    f.ws_item_sk, 
    f.ws_sales_price, 
    f.cumulative_sales,
    f.total_orders,
    f.total_profit,
    CASE 
        WHEN f.total_profit IS NULL THEN 'No Profit'
        WHEN f.total_profit <= 0 THEN 'Break-Even'
        ELSE 'Profit Margin'
    END AS profit_status
FROM 
    FilteredSales f 
LEFT JOIN 
    reason r ON f.ws_order_number = r.r_reason_sk
WHERE 
    f.total_orders > 0 
    AND EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk = (SELECT ss.ss_store_sk FROM store_sales ss WHERE ss.ss_item_sk = f.ws_item_sk LIMIT 1)
    )
ORDER BY 
    f.total_profit DESC NULLS LAST
LIMIT 100
OFFSET 0;
