
WITH RankedSales AS (
    SELECT 
        ws_order_number,
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_sales_price DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
), 
AggregatedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales
    WHERE 
        ws_sales_price > 0 OR ws_quantity IS NULL
    GROUP BY 
        ws_item_sk
), 
PromotionalItems AS (
    SELECT 
        ws_item_sk,
        p.p_discount_active
    FROM 
        web_sales ws 
    LEFT JOIN 
        promotion p ON ws.promo_sk = p.p_promo_sk
    WHERE 
        p.p_discount_active = 'Y'
)
SELECT 
    COALESCE(ca_city, 'Unknown') AS city,
    ia.total_sales,
    ra.rank,
    pa.p_discount_active,
    CASE 
        WHEN ia.order_count > 100 THEN 'High Volume'
        WHEN ia.order_count BETWEEN 50 AND 100 THEN 'Medium Volume'
        ELSE 'Low Volume' 
    END AS order_volume,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ') AS customers
FROM 
    customer_address ca
FULL OUTER JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    AggregatedSales ia ON ia.ws_item_sk = c.c_customer_sk
JOIN 
    RankedSales ra ON ra.ws_order_number = ia.ws_item_sk
LEFT JOIN 
    PromotionalItems pa ON pa.ws_item_sk = ia.ws_item_sk
WHERE 
    ca.ca_state IS NOT NULL 
    AND (ia.total_sales > 1000 OR pa.p_discount_active IS NOT NULL)
GROUP BY 
    ca.ca_city, ia.total_sales, ra.rank, pa.p_discount_active
HAVING 
    COUNT(c.c_customer_sk) > 1 
ORDER BY 
    total_sales DESC, city ASC;
