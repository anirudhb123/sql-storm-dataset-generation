
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(ws2.ws_sold_date_sk) FROM web_sales ws2)
),
CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        SUM(ws.ws_net_profit) AS TotalSpent
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status, cd.cd_credit_rating
),
TopCustomers AS (
    SELECT 
        ci.c_customer_id,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_credit_rating,
        ci.TotalSpent,
        DENSE_RANK() OVER (ORDER BY ci.TotalSpent DESC) AS CustomerRank
    FROM 
        CustomerInfo ci
    WHERE 
        ci.TotalSpent > 1000
)
SELECT 
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.cd_credit_rating,
    tc.TotalSpent,
    COALESCE(rs.ws_sales_price, 0) AS LastSalePrice,
    CASE 
        WHEN tc.cd_gender = 'M' THEN 'Male'
        WHEN tc.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS GenderDescription
FROM 
    TopCustomers tc
LEFT JOIN 
    RankedSales rs ON tc.c_customer_id = (SELECT c.c_customer_id FROM customer c WHERE c.c_customer_sk = rs.ws_item_sk LIMIT 1)
WHERE 
    tc.CustomerRank <= 10
ORDER BY 
    tc.CustomerRank;
