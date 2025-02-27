
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_net_paid,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
),
CustomerReturns AS (
    SELECT 
        sr.sr_item_sk, 
        SUM(sr.sr_return_quantity) AS total_returned_quantity,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr 
    WHERE 
        sr.sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr.sr_item_sk
),
ProfitSummary AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_paid) AS total_net_paid,
        SUM(cr.total_return_amount) AS total_return_amount,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    LEFT JOIN 
        CustomerReturns cr ON rs.ws_item_sk = cr.sr_item_sk
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    ps.ws_item_sk,
    ps.total_net_paid,
    COALESCE(ps.total_return_amount, 0) AS total_return_amount,
    (ps.total_net_paid - COALESCE(ps.total_return_amount, 0)) AS net_profit_loss,
    CASE 
        WHEN (ps.total_net_paid - COALESCE(ps.total_return_amount, 0)) > 0 THEN 'Profit'
        ELSE 'Loss' 
    END AS Profitability,
    (SELECT COUNT(DISTINCT cd.cd_demo_sk) 
     FROM customer_demographics cd 
     WHERE cd.cd_credit_rating = 'Excellent' 
     AND cd.cd_dep_count > 2 
     AND cd.cd_gender = (CASE WHEN ps.net_profit_loss > 0 THEN 'M' ELSE 'F' END)) AS excellent_customer_count
FROM 
    ProfitSummary ps
WHERE 
    ps.order_count > (SELECT AVG(order_count) FROM ProfitSummary)
ORDER BY 
    net_profit_loss DESC, ps.ws_item_sk;
