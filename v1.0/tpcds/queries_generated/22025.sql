
WITH RECURSIVE SalesQuantities AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_quantity) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk

    UNION ALL

    SELECT 
        cs_item_sk,
        SUM(cs_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY cs_item_sk ORDER BY SUM(cs_quantity) DESC) AS rnk
    FROM 
        catalog_sales
    GROUP BY 
        cs_item_sk
)

SELECT 
    a.ca_address_id,
    CTE1.customer_id,
    COALESCE(CTE1.total_quantity, 0) AS total_web_sales,
    COALESCE(CTE2.total_quantity, 0) AS total_catalog_sales,
    CASE 
        WHEN COALESCE(CTE1.total_quantity, 0) > COALESCE(CTE2.total_quantity, 0) THEN 'More Web Sales'
        WHEN COALESCE(CTE1.total_quantity, 0) < COALESCE(CTE2.total_quantity, 0) THEN 'More Catalog Sales'
        ELSE 'Equal Sales'
    END AS Sales_Comparison,
    SM.sm_type,
    CASE 
        WHEN (EXTRACT(DOW FROM D.d_date) IN (0, 6)) THEN 'Weekend'
        ELSE 'Weekday'
    END AS Day_Type
FROM 
    customer_address a
LEFT JOIN 
    customer CTE1 ON a.ca_address_sk = CTE1.c_current_addr_sk 
LEFT JOIN 
    (SELECT ws_item_sk, SUM(ws_quantity) AS total_quantity FROM web_sales GROUP BY ws_item_sk) CTE1 ON CTE1.ws_item_sk IN (SELECT * FROM SalesQuantities WHERE rnk = 1)
LEFT JOIN 
    (SELECT cs_item_sk, SUM(cs_quantity) AS total_quantity FROM catalog_sales GROUP BY cs_item_sk) CTE2 ON CTE2.cs_item_sk IN (SELECT * FROM SalesQuantities WHERE rnk = 1)
LEFT JOIN 
    ship_mode SM ON  SM.sm_ship_mode_sk = 
        (SELECT 
            wr_reason_sk 
         FROM 
            web_returns 
         WHERE 
            wr_return_quantity IS NOT NULL 
            ORDER BY wr_return_quantity DESC 
            LIMIT 1)
JOIN 
    date_dim D ON D.d_date < CURRENT_DATE 
WHERE 
    a.ca_state IS NOT NULL 
    AND a.ca_country <> 'USA' 
ORDER BY 
    COALESCE(CTE1.total_quantity, 0) DESC, 
    COALESCE(CTE2.total_quantity, 0) DESC 
LIMIT 50;
