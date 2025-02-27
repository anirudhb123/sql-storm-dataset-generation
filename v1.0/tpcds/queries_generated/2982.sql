
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.order_number,
        ws_item_sk,
        ws_quantity,
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1995
),
TotalReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk > (SELECT d_date_sk FROM date_dim WHERE d_date = CURRENT_DATE - INTERVAL '30 DAY')
    GROUP BY 
        wr_item_sk
)
SELECT 
    isv.i_item_id,
    COALESCE(SUM(rs.ws_quantity), 0) AS total_sold_quantity,
    COALESCE(SUM(rs.ws_net_profit), 0) AS total_net_profit,
    COALESCE(tr.total_returned, 0) AS total_returned,
    COALESCE(tr.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN SUM(rs.ws_net_profit) IS NULL THEN 'No Sales'
        WHEN SUM(rs.ws_net_profit) - COALESCE(tr.total_return_amount, 0) < 0 THEN 'Negative Profit'
        ELSE 'Profit'
    END AS profit_status
FROM 
    item isv
LEFT JOIN 
    RankedSales rs ON isv.i_item_sk = rs.ws_item_sk
LEFT JOIN 
    TotalReturns tr ON isv.i_item_sk = tr.wr_item_sk
WHERE 
    isv.i_current_price IS NOT NULL
GROUP BY 
    isv.i_item_id, tr.total_returned, tr.total_return_amount
HAVING 
    SUM(rs.ws_quantity) > 100
ORDER BY 
    total_net_profit DESC, total_sold_quantity DESC
LIMIT 100;
