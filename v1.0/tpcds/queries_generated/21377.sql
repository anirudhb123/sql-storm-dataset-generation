
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        COUNT(*) OVER (PARTITION BY ws.web_site_sk) AS total_sales,
        CASE
            WHEN ws.ws_net_profit IS NULL THEN 'No Profit'
            WHEN ws.ws_net_profit < 0 THEN 'Loss'
            ELSE 'Profit'
        END AS profit_status
    FROM web_sales ws
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim d WHERE d.d_year = 2023) 
    AND cd.cd_marital_status IS NOT NULL
), FilteredReturns AS (
    SELECT 
        sr.sr_ticket_number,
        SUM(sr.sr_return_quantity) AS total_returned,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    INNER JOIN RankedSales rs ON sr.sr_ticket_number = rs.ws_order_number
    WHERE sr.sr_return_quantity > 0
    GROUP BY sr.sr_ticket_number
), FinalReport AS (
    SELECT 
        rs.web_site_sk,
        rs.ws_order_number,
        rs.rank_profit,
        rs.total_sales,
        rs.profit_status,
        COALESCE(fr.total_returned, 0) AS total_returned,
        COALESCE(fr.total_net_loss, 0) AS total_net_loss,
        CASE 
            WHEN fr.total_returned > 0 AND fr.total_net_loss > 0 THEN 'High Return & Loss'
            WHEN fr.total_returned > 0 THEN 'High Return'
            WHEN fr.total_net_loss > 0 THEN 'High Loss'
            ELSE 'Normal'
        END AS return_loss_status
    FROM RankedSales rs
    LEFT JOIN FilteredReturns fr ON rs.ws_order_number = fr.sr_ticket_number
)
SELECT 
    f.web_site_sk,
    f.ws_order_number,
    f.rank_profit,
    f.total_sales,
    f.profit_status,
    f.total_returned,
    f.total_net_loss,
    f.return_loss_status
FROM FinalReport f
WHERE f.rank_profit <= 5
ORDER BY f.web_site_sk, f.rank_profit;
