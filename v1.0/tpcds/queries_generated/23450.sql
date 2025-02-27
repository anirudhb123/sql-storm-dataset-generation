
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
    GROUP BY 
        ws.ws_item_sk
),
highest_profit AS (
    SELECT 
        hs.ws_item_sk,
        hs.total_quantity,
        hs.total_net_profit
    FROM 
        ranked_sales hs
    WHERE 
        hs.profit_rank = 1
),
customer_info AS (
    SELECT 
        c.c_customer_id,
        c.c_birth_year,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Unknown'
        END AS gender,
        COUNT(DISTINCT cd.cd_demo_sk) AS demo_count
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_id, c.c_birth_year, cd.cd_gender
)
SELECT 
    c.c_customer_id,
    c.c_birth_year,
    COALESCE(ci.gender, 'None') AS gender_classification,
    hs.number_of_high_profit_items,
    (SELECT COUNT(*) FROM customer_info ci_sub WHERE c.c_customer_id = ci_sub.c_customer_id) AS total_demo_categories
FROM 
    customer c
LEFT JOIN 
    highest_profit hs ON c.c_customer_sk = hs.ws_item_sk
LEFT JOIN 
    customer_info ci ON ci.c_customer_id = c.c_customer_id
WHERE 
    (c.c_birth_year IS NOT NULL OR c.c_email_address LIKE '%@yourcompany.com')
    AND (CASE 
            WHEN c.c_birth_year IS NULL THEN true
            ELSE c.c_birth_year < 1990
          END)
ORDER BY 
    c.c_customer_id, total_demo_categories DESC
FETCH FIRST 10 ROWS ONLY;
