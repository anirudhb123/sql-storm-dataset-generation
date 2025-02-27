
WITH SalesData AS (
    SELECT 
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        cd.cd_gender,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_sales_price DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT d_date_sk 
            FROM date_dim 
            WHERE d_year = 2023
        )
    AND 
        (cd.cd_gender IS NOT NULL OR cd.cd_income_band_sk IS NOT NULL)
),
TopSales AS (
    SELECT 
        *,
        SUM(ws_quantity) OVER (PARTITION BY ws_item_sk) AS total_quantity,
        AVG(ws_net_profit) OVER (PARTITION BY ws_item_sk) AS avg_net_profit
    FROM 
        SalesData
    WHERE 
        rn = 1
)
SELECT 
    ts.ws_order_number,
    ts.ws_item_sk,
    ts.ws_quantity,
    ts.ws_sales_price,
    ts.avg_net_profit,
    ca.ca_city,
    ca.ca_state,
    CASE 
        WHEN ts.total_quantity > 100 THEN 'High Volume'
        WHEN ts.total_quantity BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS volume_category
FROM 
    TopSales ts
LEFT JOIN 
    customer_address ca ON ts.ws_item_sk = ca.ca_address_sk
WHERE 
    ts.ws_sales_price > (SELECT AVG(ws_sales_price) FROM web_sales)
ORDER BY 
    ts.avg_net_profit DESC
LIMIT 10;
