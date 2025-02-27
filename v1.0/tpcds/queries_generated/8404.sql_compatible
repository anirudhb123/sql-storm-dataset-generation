
WITH CustomerStatistics AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS total_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        COUNT(DISTINCT ca.ca_address_sk) AS address_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        cd.cd_gender
),
SalesStatistics AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year
),
InventoryStatistics AS (
    SELECT 
        inv.inv_warehouse_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(inv.inv_quantity_on_hand) AS avg_quantity_on_hand
    FROM 
        inventory inv
    GROUP BY 
        inv.inv_warehouse_sk
)
SELECT 
    cs.cd_gender,
    cs.total_customers,
    cs.avg_purchase_estimate,
    ss.d_year,
    ss.total_sales,
    ss.total_orders,
    is.inv_warehouse_sk,
    is.total_quantity_on_hand,
    is.avg_quantity_on_hand
FROM 
    CustomerStatistics cs
JOIN 
    SalesStatistics ss ON ss.d_year BETWEEN 2020 AND 2022
JOIN 
    InventoryStatistics is ON is.total_quantity_on_hand > 100
ORDER BY 
    cs.cd_gender, ss.d_year ASC;
