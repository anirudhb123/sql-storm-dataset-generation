
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
customer_analysis AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        SUM(ws_ext_sales_price) AS total_spent
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
address_analysis AS (
    SELECT 
        ca_state,
        COUNT(ca_address_sk) AS address_count,
        MAX(ca_zip) AS max_zip,
        MIN(ca_zip) AS min_zip
    FROM 
        customer_address
    GROUP BY 
        ca_state
)
SELECT 
    ca.ca_state,
    aa.address_count,
    aa.max_zip,
    aa.min_zip,
    COALESCE(SUM(cs.total_sales), 0) AS total_sales,
    COALESCE(SUM(cs.total_quantity_sold), 0) AS total_quantity
FROM 
    address_analysis aa
LEFT JOIN 
    sales_summary cs ON cs.ws_item_sk = (
        SELECT 
            ws_item_sk 
        FROM 
            web_sales 
        WHERE 
            ws_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = aa.ca_state)
        LIMIT 1
    )
JOIN 
    customer_address ca ON aa.ca_state = ca.ca_state
GROUP BY 
    ca.ca_state, aa.address_count, aa.max_zip, aa.min_zip
ORDER BY 
    total_sales DESC
LIMIT 100;
