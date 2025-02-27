
WITH RankedWebSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_profit DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL AND 
        ws_net_profit IS NOT NULL
),
MostProfitableItems AS (
    SELECT 
        R.ws_item_sk,
        R.ws_order_number,
        R.ws_sales_price,
        R.ws_net_profit
    FROM 
        RankedWebSales R
    WHERE 
        R.rank = 1
),
DailySales AS (
    SELECT 
        d.d_date_id,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        date_dim d
    LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_date_id
),
CustomerPerformance AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
)
SELECT 
    d.d_date_id AS sales_date,
    COALESCE(dp.total_sales, 0) AS total_sales,
    COALESCE(dp.total_orders, 0) AS total_orders,
    COALESCE(cp.c_customer_id, 'Unknown') AS customer_id,
    COALESCE(cp.total_net_profit, 0) AS customer_net_profit,
    COALESCE(mp.ws_sales_price, 0) AS highest_sales_price,
    NULLIF((SELECT MAX(i.i_current_price)
            FROM item i 
            WHERE i.i_item_sk IN (SELECT ws_item_sk FROM MostProfitableItems)), 0) AS max_item_price
FROM 
    DailySales dp
FULL OUTER JOIN DailySales d ON dp.total_sales IS NOT NULL OR dp.total_orders IS NOT NULL
LEFT JOIN CustomerPerformance cp ON 1=1
LEFT JOIN MostProfitableItems mp ON 1=1
ORDER BY 
    sales_date DESC,
    customer_id,
    highest_sales_price;
