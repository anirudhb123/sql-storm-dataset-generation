
WITH RankedWebSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ship_mode_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.ship_mode_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS rank_within_mode
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    GROUP BY 
        ws.web_site_sk, ws.ship_mode_sk
),
DailyReturns AS (
    SELECT 
        sr_returned_date_sk,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returned_date_sk
),
ExtremeReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        COUNT(wr_order_number) AS order_count,
        SUM(wr_net_loss) AS total_loss,
        COUNT(DISTINCT wr_returning_cdemo_sk) AS unique_demographics
    FROM 
        web_returns
    WHERE 
        wr_return_amt < 0 AND wr_returned_date_sk IS NOT NULL
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    wa.warehouse_sk,
    wa.warehouse_name,
    MAX(ws.total_quantity) AS peak_quantity,
    COALESCE(COUNT(DISTINCT wr.returning_customer_sk), 0) AS total_customers_returned,
    CASE 
        WHEN EXISTS (SELECT 1 FROM RankedWebSales rws WHERE rws.total_net_profit > 10000) THEN 'High Profit'
        ELSE 'Standard Profit'
    END AS profit_category,
    (SELECT 
         SUM(total_returns) 
     FROM 
         DailyReturns 
     WHERE 
         sr_returned_date_sk = (SELECT MAX(sr_returned_date_sk) FROM DailyReturns)) AS total_returns_for_max_date,
    (SELECT 
         ROUND(AVG(total_loss), 2) 
     FROM 
         ExtremeReturns 
     WHERE 
         order_count > 5) AS average_loss_per_customer
FROM 
    warehouse wa
LEFT JOIN 
    RankedWebSales ws ON wa.warehouse_sk = ws.web_site_sk
LEFT OUTER JOIN 
    ExtremeReturns wr ON ws.ship_mode_sk = wr.wr_returning_customer_sk
WHERE 
    wa.warehouse_sq_ft > 1000 
    AND wa.warehouse_name NOT LIKE '%Test%'
GROUP BY 
    wa.warehouse_sk, wa.warehouse_name;
