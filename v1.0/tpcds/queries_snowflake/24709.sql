
WITH RankedSales AS (
    SELECT
        ws_item_sk,
        SUM(ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM web_sales
    WHERE ws_sold_date_sk = (
        SELECT MAX(ws_sold_date_sk) 
        FROM web_sales 
        WHERE ws_net_paid_inc_ship_tax IS NOT NULL
    )
    GROUP BY ws_item_sk
),
CustomerDetails AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band_sk
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
HighValueReturns AS (
    SELECT
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(sr_ticket_number) AS return_count
    FROM store_returns
    WHERE sr_return_quantity > 0 
    GROUP BY sr_item_sk
    HAVING SUM(sr_return_amt) > 1000
),
FinalReport AS (
    SELECT
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cs.total_net_profit,
        COALESCE(hvr.total_return_amount, 0) AS total_return,
        CASE 
            WHEN cs.total_net_profit > 5000 THEN 'Platinum'
            WHEN cs.total_net_profit BETWEEN 1000 AND 5000 THEN 'Gold'
            ELSE 'Silver'
        END AS customer_status
    FROM RankedSales rs
    JOIN CustomerDetails cd ON cd.c_customer_sk = (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_item_sk = rs.ws_item_sk 
        LIMIT 1
    )
    LEFT JOIN HighValueReturns hvr ON rs.ws_item_sk = hvr.sr_item_sk
    JOIN (
        SELECT rs.ws_item_sk, SUM(rs.total_net_profit) AS total_net_profit
        FROM RankedSales rs
        WHERE rs.profit_rank = 1
        GROUP BY rs.ws_item_sk
    ) cs ON cs.ws_item_sk = rs.ws_item_sk
)

SELECT
    f.c_first_name,
    f.c_last_name,
    f.cd_gender,
    f.total_net_profit,
    f.total_return,
    f.customer_status,
    CASE 
        WHEN f.total_return > f.total_net_profit THEN 'Return Over Profit'
        ELSE 'Profit Dominates'
    END AS financial_health
FROM FinalReport f
WHERE f.cd_gender IS NOT NULL
AND f.customer_status IN ('Platinum', 'Gold')
ORDER BY f.total_net_profit DESC, f.total_return ASC
LIMIT 100;
