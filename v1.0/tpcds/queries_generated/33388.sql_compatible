
WITH RECURSIVE Sales_CTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_quantity,
        ws_sales_price,
        ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_net_paid DESC) AS rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND ws_sold_date_sk <= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
Top_Items AS (
    SELECT 
        item.i_item_sk,
        item.i_item_id,
        item.i_product_name,
        SUM(s.ws_quantity) AS total_quantity,
        SUM(s.ws_net_paid) AS total_sales
    FROM 
        Sales_CTE s
    JOIN 
        item ON s.ws_item_sk = item.i_item_sk
    WHERE 
        s.rank <= 5
    GROUP BY 
        item.i_item_sk, item.i_item_id, item.i_product_name
),
Sales_Summary AS (
    SELECT 
        i_item_id,
        i_product_name,
        total_quantity,
        total_sales,
        CASE 
            WHEN total_sales IS NULL THEN 'No Sales'
            WHEN total_sales > 1000 THEN 'High Sales'
            ELSE 'Low Sales'
        END AS sales_category
    FROM 
        Top_Items
)
SELECT 
    a.ca_city,
    a.ca_state,
    COUNT(s.sales_category) AS category_count,
    SUM(s.total_sales) AS sales_amount
FROM 
    customer_address a
LEFT JOIN 
    customer c ON a.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
LEFT JOIN 
    Sales_Summary s ON w.ws_item_sk = s.i_item_id
GROUP BY 
    a.ca_city, a.ca_state
HAVING 
    COUNT(s.sales_category) > 0
ORDER BY 
    sales_amount DESC, a.ca_city;
