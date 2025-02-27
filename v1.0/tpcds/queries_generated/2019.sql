
WITH CustomerData AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating,
        (SELECT COUNT(DISTINCT sr.ticket_number) 
         FROM store_returns sr 
         WHERE sr.sr_customer_sk = c.c_customer_sk) AS return_count,
        (SELECT COUNT(DISTINCT wr.order_number)
         FROM web_returns wr 
         WHERE wr.wr_returning_customer_sk = c.c_customer_sk) AS web_return_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesData AS (
    SELECT 
        ws_bill_customer_sk, 
        SUM(ws_net_profit) AS total_web_profit,
        COUNT(ws_order_number) AS total_web_orders
    FROM 
        web_sales 
    GROUP BY 
        ws_bill_customer_sk
),
CombinedData AS (
    SELECT 
        cd.c_customer_sk,
        cd.c_first_name,
        cd.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.return_count,
        cd.web_return_count,
        COALESCE(sd.total_web_profit, 0) AS total_web_profit,
        COALESCE(sd.total_web_orders, 0) AS total_web_orders
    FROM 
        CustomerData cd
    LEFT JOIN 
        SalesData sd ON cd.c_customer_sk = sd.ws_bill_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_web_profit = 0 THEN 'No Sales'
        WHEN total_web_profit < 1000 THEN 'Low Profit'
        WHEN total_web_profit BETWEEN 1000 AND 5000 THEN 'Moderate Profit'
        ELSE 'High Profit'
    END AS profit_category
FROM 
    CombinedData
WHERE 
    (cd_gender = 'F' AND cd_purchase_estimate > 500)
    OR (cd_gender = 'M' AND return_count > 2)
ORDER BY 
    total_web_profit DESC,
    c_last_name ASC;
