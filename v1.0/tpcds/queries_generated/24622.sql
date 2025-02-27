
WITH RankedSales AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn,
        SUM(ws.ws_sales_price) OVER (PARTITION BY ws.ws_order_number) AS total_order_price
    FROM 
        web_sales ws
    WHERE 
        ws.ws_ship_date_sk IS NOT NULL
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT cs.cs_order_number) AS total_orders,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
SalesReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns
    FROM 
        store_returns sr
    WHERE 
        sr.sr_returned_date_sk IS NOT NULL
    GROUP BY 
        sr.sr_item_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    COALESCE(rs.total_order_price, 0) AS highest_order_price,
    COALESCE(cs.total_orders, 0) AS order_count,
    COALESCE(cr.total_returns, 0) AS total_encoded_returns,
    CASE 
        WHEN cs.total_net_profit IS NULL THEN 'No Profit'
        WHEN cs.total_net_profit > 10000 THEN 'High Profit'
        ELSE 'Medium Profit'
    END AS profit_category
FROM 
    CustomerStats cs
LEFT JOIN 
    (SELECT ws_order_number, MAX(ws_sales_price) AS total_order_price 
     FROM RankedSales 
     WHERE rn = 1 
     GROUP BY ws_order_number) rs ON cs.total_orders > 0
LEFT JOIN 
    SalesReturns cr ON cs.c_customer_sk = cr.sr_item_sk
WHERE 
    (cs.cd_gender = 'F' OR cs.cd_gender IS NULL)
    AND (cs.total_orders > 5 OR cr.total_returns IS NULL)
ORDER BY 
    cs.c_customer_sk ASC, 
    total_order_price DESC;
