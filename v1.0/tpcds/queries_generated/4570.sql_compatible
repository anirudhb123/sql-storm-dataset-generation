
WITH SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        ws.bill_cdemo_sk,
        ws.ship_mode_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        DENSE_RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk BETWEEN 20200101 AND 20201231
),
HighValueCustomers AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(sd.ws_net_profit) AS total_profit,
        COUNT(sd.bill_customer_sk) AS purchase_count
    FROM 
        customer_demographics cd
    JOIN 
        SalesData sd ON cd.cd_demo_sk = sd.bill_cdemo_sk
    WHERE 
        cd.cd_gender = 'F' 
        AND cd.cd_marital_status IN ('M', 'S')
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
AvgSale AS (
    SELECT 
        AVG(total_profit) AS avg_profit
    FROM 
        HighValueCustomers
)
SELECT 
    h.cd_gender,
    h.cd_marital_status,
    h.cd_credit_rating,
    h.total_profit,
    CASE 
        WHEN h.total_profit > a.avg_profit THEN 'Above Average'
        ELSE 'Below Average'
    END AS profit_comparison
FROM 
    HighValueCustomers h
CROSS JOIN 
    AvgSale a
ORDER BY 
    h.total_profit DESC
LIMIT 10;
