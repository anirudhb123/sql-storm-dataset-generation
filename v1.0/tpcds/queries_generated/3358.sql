
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.ws_item_sk, ws.ws_order_number
),
TopItems AS (
    SELECT 
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_profit
    FROM 
        RankedSales ri
    WHERE 
        ri.profit_rank <= 5
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        cd.cd_credit_rating
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
SalesWithCustomer AS (
    SELECT 
        ti.*,
        ci.c_customer_sk,
        ci.c_first_name,
        ci.c_last_name,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.cd_purchase_estimate,
        ci.cd_credit_rating
    FROM 
        TopItems ti
    JOIN 
        web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    JOIN 
        CustomerInfo ci ON ws.ws_bill_customer_sk = ci.c_customer_sk
)
SELECT 
    s.warehouse_id,
    COUNT(DISTINCT swc.c_customer_sk) AS number_of_customers,
    SUM(swc.total_profit) AS total_profit,
    AVG(swc.total_quantity) AS avg_quantity
FROM 
    SalesWithCustomer swc
JOIN 
    warehouse s ON s.w_warehouse_sk = swc.ws_warehouse_sk
WHERE 
    swc.total_profit > (SELECT AVG(total_profit) FROM SalesWithCustomer)
GROUP BY 
    s.warehouse_id
ORDER BY 
    total_profit DESC
LIMIT 10;
