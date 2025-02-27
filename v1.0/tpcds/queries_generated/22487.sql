
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        COUNT(ws_order_number) OVER (PARTITION BY ws_item_sk) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS item_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
), 
HighVolumeItems AS (
    SELECT 
        r.ws_item_sk,
        r.total_quantity,
        d.d_year,
        d.d_month_seq,
        CASE 
            WHEN r.total_quantity IS NULL THEN 'UNKNOWN'
            ELSE CASE 
                WHEN r.total_quantity > 1000 THEN 'HIGH'
                WHEN r.total_quantity > 500 THEN 'MEDIUM'
                ELSE 'LOW'
            END 
        END AS sales_category
    FROM 
        RankedSales r
    JOIN 
        date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = r.ws_item_sk)
)

SELECT 
    a.ca_city,
    COUNT(c.c_customer_sk) AS customer_count,
    SUM(COALESCE(i.i_current_price, 0)) AS total_inventory_value,
    MAX(h.total_quantity) AS max_item_quantity,
    MIN(h.total_quantity) AS min_item_quantity,
    h.sales_category,
    d.d_year,
    d.d_month_seq
FROM 
    customer_address a
LEFT JOIN 
    customer c ON c.c_current_addr_sk = a.ca_address_sk
LEFT JOIN 
    inventory i ON i.inv_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_quantity > 100)
LEFT JOIN 
    HighVolumeItems h ON h.ws_item_sk = i.inv_item_sk
JOIN 
    date_dim d ON d.d_date_sk = i.inv_date_sk
WHERE 
    a.ca_state = 'CA' 
    AND (h.total_quantity > 100 OR h.total_quantity IS NULL)
GROUP BY 
    a.ca_city, h.sales_category, d.d_year, d.d_month_seq
HAVING 
    COUNT(c.c_customer_sk) > 5 
    AND MAX(h.total_quantity) IS NOT NULL
ORDER BY 
    h.sales_category DESC, customer_count ASC;
