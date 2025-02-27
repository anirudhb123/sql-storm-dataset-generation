
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_item_sk, 
        ws.ws_sales_price, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rn,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_order_number) AS total_sales_per_order,
        DENSE_RANK() OVER (ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_gender = 'F' AND cd.cd_purchase_estimate > 1000
),
CustomerReturns AS (
    SELECT 
        wr.wr_order_number, 
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_return_quantity) AS returns_count
    FROM web_returns wr
    GROUP BY wr.wr_order_number
),
FinalEvaluation AS (
    SELECT 
        rs.ws_order_number,
        MAX(rs.ws_sales_price) AS max_sales_price,
        COALESCE(cr.total_returns, 0) AS total_returns,
        rs.sales_rank
    FROM RankedSales rs
    LEFT JOIN CustomerReturns cr ON rs.ws_order_number = cr.wr_order_number
    GROUP BY rs.ws_order_number, rs.sales_rank
    HAVING MAX(rs.ws_sales_price) > 500 OR COALESCE(cr.total_returns, 0) > 5
)

SELECT 
    fe.ws_order_number,
    fe.max_sales_price,
    fe.total_returns,
    fe.sales_rank,
    CASE 
        WHEN fe.total_returns > 5 THEN 'High Return Rate'
        ELSE 'Standard'
    END AS return_status,
    CASE 
        WHEN fe.sales_rank <= 10 THEN 'Top Seller'
        ELSE 'Average Seller'
    END AS seller_status
FROM FinalEvaluation fe
ORDER BY fe.sales_rank, fe.total_returns DESC;
