
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_sales_price,
        ws_quantity,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS sales_rank,
        (ws_sales_price * ws_quantity) AS total_sales
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2455000 AND 2455005
),
MaxSales AS (
    SELECT 
        ws_item_sk,
        MAX(total_sales) AS max_total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank = 1
    GROUP BY 
        ws_item_sk
)
SELECT 
    i.i_item_id,
    i.i_product_name,
    COALESCE(m.max_total_sales, 0) AS highest_sale,
    STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name), ', ' ORDER BY c.c_last_name) AS top_customers
FROM 
    item i
LEFT JOIN 
    MaxSales m ON i.i_item_sk = m.ws_item_sk
LEFT JOIN 
    web_sales ws ON i.i_item_sk = ws.ws_item_sk
LEFT JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE 
    i.i_current_price > 20.00
    AND (m.max_total_sales IS NULL OR m.max_total_sales > (SELECT AVG(total_sales)
                                                            FROM RankedSales))
GROUP BY 
    i.i_item_id,
    i.i_product_name
ORDER BY 
    highest_sale DESC
FETCH FIRST 100 ROWS ONLY;
