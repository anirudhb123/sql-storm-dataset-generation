
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_profit DESC) AS rnk
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE i.i_current_price > 50.00 AND ws.ws_sold_date_sk IN (
        SELECT DISTINCT d.d_date_sk 
        FROM date_dim d 
        WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) 
        AND d.d_moy BETWEEN 5 AND 7
    )
),
HighProfit AS (
    SELECT 
        rs.ws_order_number,
        SUM(rs.ws_net_profit) AS total_net_profit
    FROM RankedSales rs
    WHERE rs.rnk <= 5
    GROUP BY rs.ws_order_number
),

CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_count
    FROM store_returns sr
    LEFT JOIN web_sales ws ON sr.sr_item_sk = ws.ws_item_sk
    WHERE sr.sr_returned_date_sk >= (
        SELECT MIN(d.d_date_sk) 
        FROM date_dim d 
        WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim) - 1
    )
    GROUP BY sr.sr_customer_sk
),

CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_buy_potential,
        COALESCE(cd.cd_purchase_estimate, 0) AS purchase_estimate,
        COALESCE(cr.return_count, 0) AS return_count
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN CustomerReturns cr ON c.c_customer_sk = cr.sr_customer_sk
)

SELECT 
    cd.cd_gender,
    cd.cd_marital_status,
    COUNT(DISTINCT cd.c_customer_sk) AS customer_count,
    SUM(cd.purchase_estimate) AS total_purchase_estimate,
    AVG(cd.return_count) AS avg_returns
FROM CustomerDemographics cd
JOIN HighProfit hp ON cd.c_customer_sk IN (
    SELECT DISTINCT ws.ws_bill_customer_sk 
    FROM web_sales ws 
    WHERE ws.ws_order_number IN (SELECT ws_order_number FROM HighProfit)
)
GROUP BY cd.cd_gender, cd.cd_marital_status
HAVING SUM(cd.purchase_estimate) > (SELECT AVG(purchase_estimate) FROM CustomerDemographics)
ORDER BY customer_count DESC,
         total_purchase_estimate ASC NULLS LAST;
