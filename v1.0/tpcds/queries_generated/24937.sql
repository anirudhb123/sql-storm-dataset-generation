
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank,
        DENSE_RANK() OVER (ORDER BY ws_sales_price) AS price_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_dep_count IS NOT NULL 
        AND cd.cd_birth_year <= 1990
),
WarehouseStats AS (
    SELECT 
        w.w_warehouse_id,
        SUM(i.inv_quantity_on_hand) AS total_inventory,
        AVG(i.inv_quantity_on_hand) AS avg_inventory
    FROM 
        inventory i 
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_id
),
SalesSummary AS (
    SELECT 
        rs.ws_order_number,
        cd.c_first_name,
        cd.c_last_name,
        ws.ws_sales_price,
        ws.ws_net_paid,
        COALESCE(w.total_inventory, 0) AS warehouse_inventory
    FROM 
        RankedSales rs
    JOIN 
        CustomerDetails cd ON rs.ws_order_number IN (SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_item_sk = rs.ws_item_sk)
    LEFT JOIN 
        WarehouseStats w ON w.w_warehouse_id = (SELECT w_warehouse_id FROM warehouse WHERE w_warehouse_sk = (SELECT DISTINCT ws_warehouse_sk FROM web_sales WHERE ws_order_number = rs.ws_order_number LIMIT 1))
    WHERE 
        rs.rank <= 5
    ORDER BY 
        ws_net_paid DESC
)
SELECT 
    ss.ws_order_number,
    ss.c_first_name,
    ss.c_last_name,
    ss.ws_sales_price,
    ss.ws_net_paid,
    ss.warehouse_inventory
FROM 
    SalesSummary ss
WHERE 
    ss.warehouse_inventory > (SELECT AVG(warehouse_inventory) FROM WarehouseStats)
    OR ss.ws_sales_price < ALL (SELECT DISTINCT ws_sales_price FROM web_sales WHERE ws_quantity > 10)
ORDER BY 
    ss.ws_net_paid DESC, 
    ss.c_last_name ASC;
