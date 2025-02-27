
WITH RecursiveSalesCTE AS (
    SELECT 
        w.w_warehouse_id,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(ws.ws_order_number) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY SUM(ws.ws_net_profit) DESC) AS sales_rank
    FROM 
        warehouse w
    INNER JOIN web_sales ws ON w.w_warehouse_sk = ws.ws_warehouse_sk
    GROUP BY 
        w.w_warehouse_id, ws.ws_order_number, ws.ws_sold_date_sk
    HAVING 
        SUM(ws.ws_net_profit) IS NOT NULL
),
DistinctCustomer AS (
    SELECT DISTINCT
        c.c_customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS full_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        cd.cd_marital_status = 'M'
),
SalesSummary AS (
    SELECT 
        ss.ss_item_sk,
        SUM(ss.ss_net_profit) AS total_sales_net_profit,
        SUM(ss.ss_quantity) AS total_quantity_sold
    FROM 
        store_sales ss
    GROUP BY 
        ss.ss_item_sk
)
SELECT 
    r.w_warehouse_id,
    r.ws_order_number,
    r.total_net_profit,
    d.full_name,
    s.total_sales_net_profit,
    s.total_quantity_sold
FROM 
    RecursiveSalesCTE r
LEFT JOIN 
    DistinctCustomer d ON r.ws_order_number IN (
        SELECT 
            ws.ws_order_number 
        FROM 
            web_sales ws 
        WHERE 
            ws.ws_order_number IS NOT NULL
    )
JOIN 
    SalesSummary s ON r.ws_order_number = s.ss_item_sk
WHERE 
    r.total_net_profit > 0
ORDER BY 
    r.total_net_profit DESC, 
    r.w_warehouse_id;
