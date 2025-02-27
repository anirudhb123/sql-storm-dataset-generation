
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        MAX(ws.ws_ship_date_sk) AS last_purchase_date
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id
),
SalesPerMonth AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_net_profit) AS monthly_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
HighValueCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_profit,
        cs.total_orders,
        cs.last_purchase_date,
        ROW_NUMBER() OVER (ORDER BY cs.total_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_profit > (SELECT AVG(total_profit) FROM CustomerSales)
),
InventoryStatus AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand,
        COUNT(DISTINCT inv.inv_warehouse_sk) AS warehouse_count
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_item_sk
)
SELECT 
    c.c_customer_id,
    cs.total_profit,
    cs.total_orders,
    cs.avg_order_value,
    CASE 
        WHEN cs.total_orders > 10 THEN 'Frequent Buyer'
        WHEN cs.total_orders IS NULL THEN 'No Orders'
        ELSE 'Occasional Buyer'
    END AS buyer_type,
    hs.monthly_profit,
    inv.total_on_hand,
    inv.warehouse_count
FROM 
    HighValueCustomers hs
LEFT JOIN 
    CustomerSales cs ON hs.c_customer_id = cs.c_customer_id
LEFT JOIN 
    InventoryStatus inv ON cs.c_customer_id = CAST(SUBSTRING(cs.c_customer_id, LENGTH(cs.c_customer_id) - 1, 1) AS INTEGER)
WHERE 
    hs.rank <= 10 AND (inv.total_on_hand IS NOT NULL OR inv.total_on_hand = 0)
ORDER BY 
    cs.total_profit DESC;
