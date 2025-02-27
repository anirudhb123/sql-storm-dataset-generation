
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk
),
HighValueCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_paid) > 1000
),
StorePerformance AS (
    SELECT 
        ss.s_store_sk,
        ss.s_store_name,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        AVG(ss.ss_sales_price) AS average_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions
    FROM 
        store_sales ss
    JOIN 
        store s ON ss.s_store_sk = s.s_store_sk
    WHERE 
        s.s_state = 'CA'
    GROUP BY 
        ss.s_store_sk, ss.s_store_name
),
TotalInventory AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    wh.w_warehouse_name,
    COALESCE(ss.total_quantity, 0) AS total_quantity_web,
    COALESCE(sp.total_quantity_sold, 0) AS total_quantity_store,
    COALESCE(hv.total_spent, 0) AS total_high_value_spent,
    inv.total_inventory
FROM 
    warehouse wh
LEFT JOIN 
    SalesSummary ss ON wh.w_warehouse_sk = ss.web_site_sk
LEFT JOIN 
    StorePerformance sp ON wh.w_warehouse_sk = sp.s_store_sk
LEFT JOIN 
    (SELECT MAX(total_spent) AS total_spent, c_customer_sk FROM HighValueCustomers GROUP BY c_customer_sk) hv ON true
JOIN 
    TotalInventory inv ON wh.w_warehouse_sk = inv.inv_warehouse_sk
ORDER BY 
    total_quantity_web DESC, total_quantity_store DESC;
