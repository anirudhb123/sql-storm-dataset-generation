
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank_by_profit
    FROM 
        web_sales
    GROUP BY 
        ws_order_number,
        ws_item_sk
),
TopItems AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.total_profit,
        sales.total_quantity,
        RANK() OVER (ORDER BY sales.total_profit DESC) AS profit_rank
    FROM 
        RankedSales sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.rank_by_profit = 1
),
RecentReturns AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_return_quantity) AS return_count,
        SUM(sr_refunded_cash) AS total_refund
    FROM 
        store_returns
    WHERE 
        sr_returned_date_sk > (
            SELECT 
                MAX(d_date_sk) - 30 
            FROM 
                date_dim
            WHERE 
                d_current_day = 'Y'
        )
    GROUP BY 
        sr_item_sk
)
SELECT 
    ti.i_item_id,
    ti.i_product_name,
    ti.total_profit,
    ti.total_quantity,
    COALESCE(rr.return_count, 0) AS return_count,
    COALESCE(rr.total_refund, 0) AS total_refund,
    CASE 
        WHEN COALESCE(rr.return_count, 0) > 10 THEN 'High Return'
        WHEN COALESCE(rr.return_count, 0) BETWEEN 1 AND 10 THEN 'Moderate Return'
        ELSE 'No Returns'
    END AS return_category
FROM 
    TopItems ti
LEFT JOIN 
    RecentReturns rr ON ti.i_item_id = rr.sr_item_sk
WHERE 
    ti.profit_rank <= 10
ORDER BY 
    ti.total_profit DESC, 
    ti.total_quantity DESC;
