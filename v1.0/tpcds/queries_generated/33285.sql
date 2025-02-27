
WITH RECURSIVE ItemHierarchy AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price,
        CAST(i_item_desc AS VARCHAR(100)) AS hierarchy_path,
        1 AS level
    FROM 
        item
    WHERE 
        i_item_sk IN (SELECT i_item_sk FROM catalog_sales WHERE cs_quantity > 0)
    
    UNION ALL

    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        CONCAT(ih.hierarchy_path, ' > ', i.i_item_desc),
        ih.level + 1
    FROM 
        item i
    JOIN 
        ItemHierarchy ih ON i.i_item_sk = ih.i_item_sk
    WHERE 
        ih.level < 5
),
SalesData AS (
    SELECT 
        cs.cs_order_number,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(cs.cs_order_number) AS total_orders
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sold_date_sk = (SELECT MAX(cs_inner.cs_sold_date_sk) FROM catalog_sales cs_inner)
    GROUP BY 
        cs.cs_order_number
),
CustomerAddressData AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city
),
CombinedData AS (
    SELECT 
        sd.total_profit,
        sd.total_orders,
        cad.ca_city,
        COALESCE(cad.customer_count, 0) AS customer_count,
        ih.hierarchy_path,
        ih.level
    FROM 
        SalesData sd
    JOIN 
        CustomerAddressData cad ON sd.total_orders > 0
    LEFT JOIN 
        ItemHierarchy ih ON ih.level = 1
)
SELECT 
    city,
    SUM(total_profit) AS total_profit,
    AVG(customer_count) AS average_customers,
    STRING_AGG(hierarchy_path, ', ') AS item_hierarchy
FROM 
    CombinedData
GROUP BY 
    city
ORDER BY 
    total_profit DESC
LIMIT 10;
