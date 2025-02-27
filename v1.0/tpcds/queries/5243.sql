
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_order_number DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price) AS total_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 10
    GROUP BY 
        rs.ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(ts.total_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        TopSales ts ON ts.ws_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk)
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
)
SELECT 
    cs.cd_gender,
    COUNT(DISTINCT cs.c_customer_sk) AS num_customers,
    AVG(cs.total_spent) AS avg_spent,
    SUM(cs.total_spent) AS total_spent
FROM 
    CustomerStats cs
GROUP BY 
    cs.cd_gender
ORDER BY 
    total_spent DESC
LIMIT 10;
