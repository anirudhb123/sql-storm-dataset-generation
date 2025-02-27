
WITH ranked_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        r.total_quantity,
        r.total_sales
    FROM 
        ranked_sales r
    JOIN 
        item i ON r.ws_item_sk = i.i_item_sk
    WHERE 
        r.sales_rank <= 10
)
SELECT 
    ta.i_item_id,
    ta.i_product_name,
    ta.total_quantity,
    ta.total_sales,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
    AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
FROM 
    top_items ta
JOIN 
    web_sales ws ON ta.ws_item_sk = ws.ws_item_sk
JOIN 
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
JOIN 
    customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
GROUP BY 
    ta.i_item_id, ta.i_product_name, ta.total_quantity, ta.total_sales, ca.ca_city, ca.ca_state
ORDER BY 
    ta.total_sales DESC;
