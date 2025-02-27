
WITH sales_summary AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.net_paid) AS total_net_paid,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.net_paid) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.web_site_sk, ws.web_name
),
customer_analysis AS (
    SELECT 
        ca.city,
        cd.gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(c.c_birth_year) AS avg_birth_year,
        MAX(c.c_birth_year) AS max_birth_year,
        MIN(c.c_birth_year) AS min_birth_year
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city, cd.gender
),
inventory_status AS (
    SELECT 
        inv.warehouse_sk,
        SUM(inv.quantity_on_hand) AS total_quantity,
        (SELECT MAX(inv2.inv_quantity_on_hand) 
         FROM inventory inv2 
         WHERE inv2.warehouse_sk = inv.warehouse_sk) AS max_inventory,
        (SELECT MIN(inv3.inv_quantity_on_hand) 
         FROM inventory inv3 
         WHERE inv3.warehouse_sk = inv.warehouse_sk) AS min_inventory
    FROM 
        inventory inv
    GROUP BY 
        inv.warehouse_sk
)
SELECT 
    ss.web_name AS website,
    ss.total_net_paid,
    ss.total_orders,
    ca.city,
    ca.gender,
    ca.customer_count,
    ca.avg_birth_year,
    ca.max_birth_year,
    ca.min_birth_year,
    is.warehouse_sk,
    is.total_quantity,
    is.max_inventory,
    is.min_inventory
FROM 
    sales_summary ss
JOIN 
    customer_analysis ca ON ca.city IN ('New York', 'Los Angeles')
FULL OUTER JOIN 
    inventory_status is ON is.warehouse_sk = ss.web_site_sk
WHERE 
    ss.total_orders > 100
AND 
    (is.total_quantity IS NULL OR is.total_quantity > 50)
ORDER BY 
    ss.total_net_paid DESC, 
    ca.customer_count ASC;
