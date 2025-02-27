
WITH sales_data AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20000101 AND 20001231
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
customer_data AS (
    SELECT
        c.c_customer_sk,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        SUM(ws.ws_net_profit) AS net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, gender
),
returns_data AS (
    SELECT
        wr.returning_customer_sk,
        SUM(wr.wr_return_amt) AS total_return_amt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM
        web_returns wr
    GROUP BY
        wr.returning_customer_sk
)
SELECT 
    cd.gender,
    COUNT(*) AS total_customers,
    COALESCE(SUM(sd.total_net_profit), 0) AS total_net_profit,
    COALESCE(SUM(rd.total_return_amt), 0) AS total_return_amt
FROM 
    customer_data cd
LEFT JOIN 
    sales_data sd ON cd.c_customer_sk IN (
        SELECT ws_bill_customer_sk FROM web_sales WHERE ws_bill_customer_sk = cd.c_customer_sk
    )
LEFT JOIN 
    returns_data rd ON cd.c_customer_sk = rd.returning_customer_sk
GROUP BY 
    cd.gender
ORDER BY 
    total_customers DESC;
