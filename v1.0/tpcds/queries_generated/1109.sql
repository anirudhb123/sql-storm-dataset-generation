
WITH sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
top_sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sales.total_quantity,
        sales.total_sales
    FROM 
        sales_summary sales
    JOIN 
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE 
        sales.sales_rank <= 5
),
top_customers AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
    HAVING 
        SUM(ws_net_paid_inc_tax) > 1000
),
customer_details AS (
    SELECT 
        customer.c_customer_id,
        customer.c_first_name,
        customer.c_last_name,
        demographics.cd_gender
    FROM 
        customer
    JOIN 
        customer_demographics demographics ON customer.c_current_cdemo_sk = demographics.cd_demo_sk
    WHERE 
        customer.c_current_addr_sk IS NOT NULL
)
SELECT 
    cd.c_customer_id,
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    ts.i_product_name,
    ts.total_quantity,
    ts.total_sales,
    tc.total_spent
FROM 
    top_sales ts
JOIN 
    top_customers tc ON ts.i_item_sk = tc.ws_bill_customer_sk
JOIN 
    customer_details cd ON tc.ws_bill_customer_sk = cd.c_customer_id
LEFT JOIN 
    customer_address ca ON customer.c_current_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA'
    AND ts.total_sales > 500
ORDER BY 
    ts.total_sales DESC
LIMIT 100;
