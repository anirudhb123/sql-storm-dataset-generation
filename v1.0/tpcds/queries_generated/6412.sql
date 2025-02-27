
WITH aggregated_sales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        AVG(ws_sales_price) AS avg_sales_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 2450245 AND 2450300
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        a.i_item_sk,
        a.i_product_name,
        a.i_brand,
        b.total_quantity,
        b.total_net_paid,
        b.avg_sales_price,
        RANK() OVER (ORDER BY b.total_net_paid DESC) AS sales_rank
    FROM 
        item a
    JOIN 
        aggregated_sales b ON a.i_item_sk = b.ws_item_sk
)
SELECT 
    ti.i_product_name,
    ti.i_brand,
    ti.total_quantity,
    ti.total_net_paid,
    ti.avg_sales_price,
    c.cd_gender,
    c.cd_marital_status,
    ca.ca_city,
    ca.ca_state
FROM 
    top_items ti
JOIN 
    customer c ON c.c_customer_sk IN (
        SELECT 
            ws_bill_customer_sk 
        FROM 
            web_sales 
        WHERE 
            ws_item_sk = ti.i_item_sk
    )
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_net_paid DESC;
