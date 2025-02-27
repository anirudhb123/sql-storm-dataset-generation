
WITH Item_Sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_sales_count,
        AVG(ws.ws_sales_price) AS avg_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ws_item_sk
),
Customer_Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        cd.cd_demo_sk
),
Top_Items AS (
    SELECT 
        is.ws_item_sk,
        is.total_net_profit,
        is.total_sales_count,
        is.avg_sales_price
    FROM 
        Item_Sales is
    ORDER BY 
        is.total_net_profit DESC
    LIMIT 10
)
SELECT 
    ti.ws_item_sk,
    ti.total_net_profit,
    ti.total_sales_count,
    ti.avg_sales_price,
    cd.unique_customers,
    cd.avg_purchase_estimate
FROM 
    Top_Items ti
JOIN 
    Customer_Demographics cd ON ti.ws_item_sk = cd.cd_demo_sk
ORDER BY 
    ti.total_net_profit DESC;
