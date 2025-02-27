
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS number_of_sales
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price > 50
    GROUP BY 
        ws.ws_item_sk
),
ReturnsData AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amt,
        COUNT(sr.sr_ticket_number) AS number_of_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_item_sk
),
FinalReport AS (
    SELECT 
        rc.c_customer_id,
        rc.c_first_name,
        rc.c_last_name,
        COALESCE(sd.total_net_profit, 0) AS total_sales_profit,
        COALESCE(rd.total_return_amt, 0) AS total_return_amt,
        (COALESCE(sd.total_net_profit, 0) - COALESCE(rd.total_return_amt, 0)) AS net_profit_after_returns
    FROM 
        RankedCustomers rc
        LEFT JOIN SalesData sd ON rc.c_customer_id = sd.ws_item_sk
        LEFT JOIN ReturnsData rd ON sd.ws_item_sk = rd.sr_item_sk
    WHERE 
        rc.rn <= 10
)
SELECT 
    *,
    CASE 
        WHEN net_profit_after_returns > 1000 THEN 'High Profit'
        WHEN net_profit_after_returns BETWEEN 500 AND 1000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    FinalReport
ORDER BY 
    net_profit_after_returns DESC;
