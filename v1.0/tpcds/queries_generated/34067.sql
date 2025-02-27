
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
    HAVING 
        SUM(ws.ws_net_profit) > 1000
    UNION ALL
    SELECT 
        ch.c_customer_sk,
        ch.c_first_name,
        ch.c_last_name,
        ch.cd_gender,
        ch.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        sales_hierarchy sh
    JOIN 
        customer ch ON sh.c_customer_sk = ch.c_current_hdemo_sk
    LEFT JOIN 
        web_sales ws ON ch.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        ch.c_customer_sk, ch.c_first_name, ch.c_last_name, ch.cd_gender, ch.cd_marital_status
)
SELECT 
    s.c_first_name,
    s.c_last_name,
    s.cd_gender,
    s.cd_marital_status,
    COALESCE(s.total_profit, 0) AS total_profit,
    DENSE_RANK() OVER (ORDER BY COALESCE(s.total_profit, 0) DESC) AS rank
FROM 
    sales_hierarchy s
JOIN 
    customer_address ca ON s.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    store st ON st.s_store_sk = (SELECT ss_store_sk FROM store_sales WHERE ss_customer_sk = s.c_customer_sk ORDER BY ss_net_paid DESC LIMIT 1)
WHERE 
    ca.ca_state = 'NY' OR ca.ca_country IS NULL
ORDER BY 
    rank
LIMIT 10;
