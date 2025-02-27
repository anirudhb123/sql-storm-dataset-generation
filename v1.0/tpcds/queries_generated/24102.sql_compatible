
WITH RECURSIVE customer_tree AS (
    SELECT 
        c.c_customer_sk AS customer_id,
        c.c_first_name,
        c.c_last_name,
        c.c_birth_year,
        NULL AS parent_id
    FROM 
        customer c 
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    
    UNION ALL
    
    SELECT 
        c2.c_customer_sk,
        c2.c_first_name,
        c2.c_last_name,
        c2.c_birth_year,
        ct.customer_id
    FROM 
        customer c2
    JOIN 
        store s ON s.s_store_sk = c2.c_current_addr_sk
    JOIN 
        customer_tree ct ON ct.customer_id = c2.c_current_cdemo_sk
    WHERE 
        s.s_state = 'CA'
),
sales_summary AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ws.ws_net_profit) DESC) AS item_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        i.i_item_id
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT_WS(', ', ca.ca_street_number, ca.ca_street_name, ca.ca_city, ca.ca_state) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country IS NOT NULL
)
SELECT 
    ct.customer_id,
    ct.c_first_name,
    ct.c_last_name,
    ct.c_birth_year,
    ss.total_quantity,
    ss.total_profit,
    ai.full_address
FROM 
    customer_tree ct
LEFT JOIN 
    sales_summary ss ON ss.item_rank = 1 
LEFT JOIN 
    address_info ai ON ai.ca_address_sk = ct.customer_id 
WHERE 
    COALESCE(ss.total_profit, 0) > 0 OR ct.c_birth_year IS NULL
ORDER BY 
    ct.c_last_name ASC, ct.c_first_name ASC;
