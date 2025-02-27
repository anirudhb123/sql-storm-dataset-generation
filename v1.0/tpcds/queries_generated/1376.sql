
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sale_rank
    FROM web_sales ws
    WHERE ws.ws_sold_date_sk BETWEEN 10000 AND 10200
),
InventoryCheck AS (
    SELECT 
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM inventory inv
    GROUP BY inv.inv_item_sk
),
SalesSummary AS (
    SELECT 
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_sales,
        SUM(cs.cs_net_paid) AS total_revenue
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk IN (SELECT DISTINCT ws_sold_date_sk FROM web_sales WHERE ws_quantity > 5)
    GROUP BY cs.cs_item_sk
)
SELECT 
    ca.ca_address_id,
    ci.c_first_name,
    ci.c_last_name,
    SUM(COALESCE(ss.total_sales, 0)) AS total_sales,
    SUM(COALESCE(ss.total_revenue, 0)) AS total_revenue,
    COALESCE(iv.total_quantity, 0) AS warehouse_quantity,
    COUNT(DISTINCT rs.ws_order_number) AS order_count,
    CASE 
        WHEN SUM(COALESCE(ss.total_revenue, 0)) IS NULL THEN 'No Revenue' 
        ELSE 'Revenue Exists'
    END AS revenue_status
FROM customer ci
LEFT JOIN customer_address ca ON ci.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN RankedSales rs ON ci.c_customer_sk = rs.ws_item_sk
LEFT JOIN SalesSummary ss ON rs.ws_item_sk = ss.cs_item_sk
LEFT JOIN InventoryCheck iv ON iv.inv_item_sk = rs.ws_item_sk
GROUP BY 
    ca.ca_address_id,
    ci.c_first_name,
    ci.c_last_name;
