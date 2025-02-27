
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold, 
        SUM(ws_sales_price) AS total_sales_value,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
), 
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        COALESCE(SS.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(SS.total_sales_value, 0) AS total_sales_value,
        CASE 
            WHEN COALESCE(SS.total_quantity_sold, 0) > 0 
                THEN COALESCE(SS.total_sales_value, 0) / COALESCE(SS.total_quantity_sold, 1) 
            ELSE 0 
        END AS average_price
    FROM 
        item i 
    LEFT JOIN sales_summary SS ON i.i_item_sk = SS.ws_item_sk
    WHERE 
        i.i_current_price BETWEEN 50 AND 150
)
SELECT 
    id.i_item_sk,
    id.i_item_desc,
    id.i_current_price,
    id.total_quantity_sold,
    id.total_sales_value,
    id.average_price,
    (SELECT COUNT(*) FROM customer WHERE c_current_cdemo_sk IS NULL) AS unknown_customers,
    (SELECT COUNT(DISTINCT c_email_address) FROM customer WHERE c_email_address IS NOT NULL) AS unique_email_count
FROM 
    item_details id
WHERE 
    id.rank <= 10
ORDER BY 
    id.total_sales_value DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;
