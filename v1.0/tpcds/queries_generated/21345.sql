
WITH RankedSales AS (
    SELECT 
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_order_number ORDER BY cs.cs_ext_sales_price DESC) as sale_rank,
        COALESCE(CASE WHEN cs.cs_quantity IS NULL OR cs.cs_quantity = 0 THEN NULL ELSE cs.cs_ext_sales_price / cs.cs_quantity END, 0) AS price_per_unit
    FROM 
        catalog_sales cs
    WHERE 
        cs.cs_sales_price IS NOT NULL AND 
        cs.cs_sales_price > 0
), 
HighValueSales AS (
    SELECT 
        rs.cs_order_number,
        SUM(rs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS num_items,
        AVG(rs.price_per_unit) AS avg_price_per_unit
    FROM 
        RankedSales rs 
    WHERE 
        rs.sale_rank <= 3 
    GROUP BY 
        rs.cs_order_number
), 
CustomerAddress AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city, 
        ca.ca_state,
        ROW_NUMBER() OVER (ORDER BY ca.ca_city) AS addr_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IS NOT NULL AND 
        ca.ca_city IS NOT NULL
), 
ShippingModes AS (
    SELECT 
        sm.sm_ship_mode_id,
        COUNT(DISTINCT cs.cs_order_number) AS order_count
    FROM 
        ship_mode sm
    JOIN 
        catalog_sales cs ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    GROUP BY 
        sm.sm_ship_mode_id
)
SELECT 
    ca.ca_city,
    ca.ca_state,
    COALESCE(hv.total_sales, 0) AS total_sales,
    COALESCE(hv.num_items, 0) AS num_items,
    COALESCE(hv.avg_price_per_unit, 0) AS avg_price_per_unit,
    sm.sm_ship_mode_id,
    sm.order_count
FROM 
    CustomerAddress ca
LEFT JOIN 
    HighValueSales hv ON hv.cs_order_number IN (SELECT DISTINCT cs.cs_order_number FROM catalog_sales cs WHERE cs.cs_order_number IS NOT NULL)
JOIN 
    ShippingModes sm ON sm.order_count > 0
WHERE 
    ca.addr_rank <= 50 AND
    (hv.total_sales IS NOT NULL OR sm.order_count > 0)
ORDER BY 
    ca.ca_city, hv.total_sales DESC;
