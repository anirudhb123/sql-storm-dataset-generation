
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ws.ws_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS ProfitRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') AND 
            (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_income_band_sk
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
HighValueCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        SUM(rs.ws_net_profit) AS TotalProfit
    FROM 
        CustomerInfo ci
    JOIN 
        RankedSales rs ON ci.c_customer_sk = rs.ws_order_number
    GROUP BY 
        ci.c_customer_sk, ci.c_first_name, ci.c_last_name, ci.cd_gender
    HAVING 
        SUM(rs.ws_net_profit) > 1000
)

SELECT 
    c.c_first_name || ' ' || c.c_last_name AS Full_Name,
    ci.cd_gender,
    SUM(ws.ws_net_profit) AS Total_Net_Profit,
    COUNT(DISTINCT ws.ws_order_number) AS Number_of_Orders,
    COALESCE(SUM(ws.ws_quantity), 0) AS Total_Quantity_Sold
FROM 
    HighValueCustomers c
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    customer_demographics ci ON c.c_customer_sk = ci.cd_demo_sk
WHERE 
    ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
GROUP BY 
    c.c_first_name, c.c_last_name, ci.cd_gender
ORDER BY 
    Total_Net_Profit DESC
LIMIT 10;
