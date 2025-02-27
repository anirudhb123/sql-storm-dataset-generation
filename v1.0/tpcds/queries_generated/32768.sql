
WITH RECURSIVE SalesData AS (
    SELECT 
        ws_date_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ws_item_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459215 AND 2459218
    GROUP BY 
        ws_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        DATEADD(day, 1, ws_date_sk),
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS order_count,
        ws_item_sk
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2459215 AND 2459218
    GROUP BY 
        ws_item_sk
),
CustomerStatistics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
ShipModeStats AS (
    SELECT 
        sm.sm_ship_mode_id,
        SUM(ws_net_paid) AS total_net_paid,
        COUNT(*) AS total_shipments,
        MAX(ws_net_profit) AS max_profit
    FROM 
        web_sales
    JOIN 
        ship_mode sm ON ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)

SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_orders,
    cs.total_spent,
    s.total_net_paid,
    s.total_shipments,
    rw.total_sales,
    rw.order_count,
    rm.*
FROM 
    CustomerStatistics cs
JOIN 
    ShipModeStats s ON cs.total_orders > s.total_shipments
LEFT JOIN 
    (SELECT MAX(total_sales) AS total_sales, item_sk FROM SalesData GROUP BY item_sk) rw ON cs.c_customer_sk = rw.item_sk
CROSS JOIN 
    (SELECT 
        COUNT(DISTINCT r.r_reason_desc) AS reason_count
     FROM 
        reason r) rm
WHERE 
    cs.total_spent > 1000
ORDER BY 
    cs.total_spent DESC
LIMIT 50;
