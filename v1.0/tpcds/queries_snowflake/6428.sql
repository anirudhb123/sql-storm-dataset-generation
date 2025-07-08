
WITH customer_summary AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr_ticket_number) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
sales_summary AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_sales_profit
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
final_summary AS (
    SELECT 
        cs.c_customer_id,
        cs.cd_gender,
        cs.cd_marital_status,
        COALESCE(ss.total_sales_profit, 0) AS total_sales_profit,
        cs.total_returns,
        cs.total_return_amount
    FROM 
        customer_summary cs
    LEFT JOIN 
        sales_summary ss ON cs.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = ss.ws_bill_customer_sk)
)
SELECT 
    fs.c_customer_id,
    fs.cd_gender,
    fs.cd_marital_status,
    fs.total_sales_profit,
    fs.total_returns,
    fs.total_return_amount,
    (fs.total_sales_profit / NULLIF(fs.total_returns, 0)) AS average_return_amt
FROM 
    final_summary fs
WHERE 
    fs.total_returns > 0
ORDER BY 
    average_return_amt DESC
LIMIT 10;
