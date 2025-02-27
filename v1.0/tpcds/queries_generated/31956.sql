
WITH RECURSIVE sales_cte AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023) - 30
    GROUP BY 
        ws_item_sk
),
top_items AS (
    SELECT 
        si.i_item_id,
        si.i_item_desc,
        scte.total_quantity,
        scte.total_profit,
        RANK() OVER (ORDER BY scte.total_profit DESC) AS item_rank
    FROM 
        sales_cte scte
    JOIN 
        item si ON scte.ws_item_sk = si.i_item_sk
), 
customer_info AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT wb.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales wb ON c.c_customer_sk = wb.ws_bill_customer_sk
    WHERE 
        cd.cd_marital_status = 'M' AND 
        cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
), 
address_count AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS num_customers
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_city
    HAVING 
        COUNT(DISTINCT c.c_customer_sk) > 5
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_profit,
    ci.c_customer_id,
    ci.order_count,
    ac.ca_city,
    ac.num_customers
FROM 
    top_items ti
JOIN 
    customer_info ci ON ti.item_rank <= 10
LEFT JOIN 
    address_count ac ON ci.c_customer_id IN (
        SELECT 
            c.c_customer_id 
        FROM 
            customer c
        WHERE 
            c.c_current_addr_sk IN (
                SELECT 
                    ca.ca_address_sk 
                FROM 
                    customer_address ca
                WHERE 
                    ca.ca_city = ac.ca_city
            )
    )
WHERE 
    (ti.total_profit IS NOT NULL OR ti.total_quantity > 0)
ORDER BY 
    ti.total_profit DESC, ci.order_count DESC;
