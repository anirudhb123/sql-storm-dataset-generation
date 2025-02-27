
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    GROUP BY 
        ws.ws_item_sk
), ReturnStats AS (
    SELECT 
        wr.wr_item_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
), CombinedStats AS (
    SELECT 
        rs.ws_item_sk,
        rs.total_sales_quantity,
        rs.total_net_paid,
        COALESCE(rs.total_sales_quantity, 0) - COALESCE(rt.total_returns, 0) AS net_sales_quantity,
        COALESCE(rt.total_return_amount, 0) AS total_return_amount,
        (CASE 
            WHEN COALESCE(rt.total_return_amount, 0) > 0 
            THEN (COALESCE(rs.total_net_paid, 0) - COALESCE(rt.total_return_amount, 0)) / COALESCE(rs.total_net_paid, NULL)
            ELSE NULL 
         END) AS return_ratio
    FROM 
        RankedSales rs
    LEFT JOIN 
        ReturnStats rt ON rs.ws_item_sk = rt.wr_item_sk
), SalesSummary AS (
    SELECT 
        cs.c_customer_id,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        catalog_sales cs
    JOIN 
        CombinedStats cms ON cs.cs_item_sk = cms.ws_item_sk
    WHERE 
        cms.sales_rank = 1
    GROUP BY 
        cs.c_customer_id
)
SELECT 
    ss.c_customer_id,
    ss.total_net_profit,
    ss.order_count,
    CASE 
        WHEN ss.order_count > 100 THEN 'High Spender'
        WHEN ss.order_count BETWEEN 51 AND 100 THEN 'Mid Spender'
        ELSE 'Low Spender'
    END AS customer_segment,
    (SELECT COUNT(DISTINCT wr_refunded_cdemo_sk) 
     FROM web_returns 
     WHERE wr_returned_date_sk IS NULL) AS null_return_count
FROM 
    SalesSummary ss
ORDER BY 
    ss.total_net_profit DESC;
