
WITH customer_stats AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT sr.ticket_number) AS total_returns,
        SUM(sr.return_amt) AS total_return_amount,
        COUNT(DISTINCT ws.order_number) AS total_web_sales,
        SUM(ws.net_paid) AS total_web_sales_amount
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
average_returns AS (
    SELECT
        AVG(total_returns) AS avg_returns,
        AVG(total_return_amount) AS avg_return_amount,
        AVG(total_web_sales) AS avg_web_sales,
        AVG(total_web_sales_amount) AS avg_web_sales_amount
    FROM 
        customer_stats
)
SELECT
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.total_returns,
    cs.total_return_amount,
    cs.total_web_sales,
    cs.total_web_sales_amount,
    ar.avg_returns,
    ar.avg_return_amount,
    ar.avg_web_sales,
    ar.avg_web_sales_amount
FROM
    customer_stats cs
CROSS JOIN 
    average_returns ar
WHERE 
    cs.total_returns > ar.avg_returns
ORDER BY 
    cs.total_return_amount DESC
LIMIT 100;
