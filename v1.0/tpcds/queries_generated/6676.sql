
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2022
    GROUP BY 
        d.d_year, c.c_gender
),
InventorySummary AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    ss.d_year, 
    ss.c_gender,
    ss.total_sales,
    ss.total_orders,
    ss.avg_profit,
    is.total_inventory
FROM 
    SalesSummary ss
JOIN 
    InventorySummary is ON ss.d_year = YEAR(CURRENT_DATE) -- Links current year to specific inventory
ORDER BY 
    ss.d_year, ss.c_gender;
