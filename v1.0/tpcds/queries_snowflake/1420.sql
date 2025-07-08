
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn,
        ws_ext_sales_price,
        ws_net_profit,
        ws_sales_price,
        ws_quantity
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        rs.ws_order_number,
        rs.ws_ext_sales_price,
        COALESCE(SUM(sr_return_quantity), 0) AS total_returns
    FROM 
        RankedSales rs
    LEFT JOIN 
        store_returns sr ON rs.ws_item_sk = sr.sr_item_sk AND rs.ws_order_number = sr.sr_ticket_number
    WHERE 
        rs.rn = 1
    GROUP BY 
        rs.ws_item_sk, rs.ws_order_number, rs.ws_ext_sales_price
),
SalesSummary AS (
    SELECT 
        ts.ws_item_sk,
        COUNT(ts.ws_order_number) AS total_orders,
        SUM(ts.ws_ext_sales_price) AS total_sales,
        AVG(ts.total_returns) AS avg_returns,
        MAX(ts.total_returns) AS max_returns
    FROM 
        TopSales ts
    GROUP BY 
        ts.ws_item_sk
)
SELECT 
    i.i_item_id,
    s.s_store_name,
    SUM(ss.total_orders) AS total_orders,
    SUM(ss.total_sales) AS total_sales,
    ss.avg_returns,
    ss.max_returns,
    DENSE_RANK() OVER (ORDER BY SUM(ss.total_sales) DESC) AS sales_rank
FROM 
    SalesSummary ss
JOIN 
    item i ON ss.ws_item_sk = i.i_item_sk
JOIN 
    store s ON s.s_store_sk = (
        SELECT 
            ss_store_sk 
        FROM 
            store_sales 
        WHERE 
            ss_item_sk = ss.ws_item_sk 
        ORDER BY 
            ss_sold_date_sk DESC 
        LIMIT 1
    )
GROUP BY 
    i.i_item_id, s.s_store_name, ss.avg_returns, ss.max_returns
HAVING 
    SUM(ss.total_sales) > 10000
ORDER BY 
    sales_rank;
