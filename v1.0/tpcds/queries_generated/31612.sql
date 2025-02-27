
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
    UNION ALL
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        total_quantity + 1,
        total_sales + ws_ext_sales_price
    FROM 
        sales_data
    WHERE 
        total_quantity < 10
), 
customer_summary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
), 
address_summary AS (
    SELECT 
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        SUM(cs.cs_net_sales) AS total_sales
    FROM 
        customer_address AS ca
    JOIN 
        customer AS c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        catalog_sales AS cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY 
        ca.ca_state
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.order_count,
    cs.total_spent,
    asu.unique_customers,
    asu.total_sales,
    sd.total_quantity,
    sd.total_sales
FROM 
    customer_summary AS cs
JOIN 
    address_summary AS asu ON cs.c_customer_sk = asu.unique_customers
LEFT JOIN 
    sales_data AS sd ON cs.order_count = sd.total_quantity
WHERE 
    cs.total_spent > (
        SELECT 
            AVG(total_spent) 
        FROM 
            customer_summary
    ) 
    AND asu.unique_customers IS NOT NULL
ORDER BY 
    cs.total_spent DESC
LIMIT 100;
