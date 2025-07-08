
WITH sales_data AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity,
        s.ss_net_paid
    FROM 
        store_sales s
    WHERE 
        s.ss_sold_date_sk BETWEEN (
            SELECT MIN(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2022
        ) AND (
            SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = 2023
        )
    UNION ALL
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        s.ss_quantity + sd.ss_quantity,
        s.ss_net_paid + sd.ss_net_paid
    FROM 
        store_sales s
    INNER JOIN 
        sales_data sd ON s.ss_item_sk = sd.ss_item_sk
    WHERE 
        sd.ss_sold_date_sk < s.ss_sold_date_sk
),
filtered_sales AS (
    SELECT 
        sd.ss_item_sk,
        SUM(sd.ss_quantity) AS total_quantity,
        SUM(sd.ss_net_paid) AS total_net_paid,
        ROW_NUMBER() OVER (PARTITION BY sd.ss_item_sk ORDER BY sd.ss_sold_date_sk DESC) AS rn
    FROM 
        sales_data sd
    GROUP BY 
        sd.ss_item_sk
    HAVING 
        rn = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(fs.total_quantity, 0) AS total_quantity,
    COALESCE(fs.total_net_paid, 0) AS total_net_paid,
    CASE 
        WHEN fs.total_net_paid IS NULL THEN 'No Sales'
        WHEN fs.total_net_paid < 1000 THEN 'Low'
        ELSE 'High'
    END AS sales_category
FROM 
    item i
LEFT JOIN 
    filtered_sales fs ON i.i_item_sk = fs.ss_item_sk
WHERE 
    i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
ORDER BY 
    total_net_paid DESC
LIMIT 10;
