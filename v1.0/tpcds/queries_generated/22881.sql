
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY c.c_customer_id ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
RecentReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(sr.sr_item_sk) AS return_count,
        SUM(sr.sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        sr.sr_customer_sk
),
CombinedData AS (
    SELECT 
        r.c_customer_id,
        r.total_quantity,
        r.total_net_profit,
        COALESCE(rr.return_count, 0) AS return_count,
        COALESCE(rr.total_return_amt, 0) AS total_return_amt
    FROM 
        RankedSales r
    LEFT JOIN RecentReturns rr ON r.c_customer_id = rr.sr_customer_sk
)
SELECT 
    cd.c_customer_id,
    cd.total_quantity,
    cd.total_net_profit,
    cd.return_count,
    cd.total_return_amt,
    CASE 
        WHEN cd.total_net_profit > 0 THEN 'Profitable'
        WHEN cd.total_net_profit < 0 AND cd.return_count > 0 THEN 'Loss with Returns'
        ELSE 'Non-Profitable'
    END AS profit_status,
    CONCAT('Customer ', cd.c_customer_id, ' has a profit status of ', 
           CASE 
               WHEN cd.total_net_profit > 0 THEN 'Profitable'
               WHEN cd.total_net_profit < 0 THEN 'Non-Profitable'
               ELSE 'Neutral'
           END) AS customer_summary
FROM 
    CombinedData cd
WHERE 
    cd.return_count > 5 OR cd.total_net_profit < 100
ORDER BY 
    cd.total_net_profit DESC,
    cd.return_count ASC
LIMIT 10;
