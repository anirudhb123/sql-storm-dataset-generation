
WITH ranked_sales AS (
    SELECT 
        ws.bill_customer_sk,
        ws.ship_date_sk,
        SUM(ws.net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.net_profit) DESC) AS rank_profit
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        ws.bill_customer_sk, ws.ship_date_sk
),
customer_details AS (
    SELECT 
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_id) AS customer_count
    FROM 
        customer_demographics cd
    JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_gender, cd.cd_marital_status, cd.cd_purchase_estimate
),
item_sales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sales_price > 100
    GROUP BY 
        i.i_item_id
)

SELECT 
    ca.ca_city,
    MAX(cs.total_profit) AS max_profit_per_city,
    SUM(cd.customer_count) AS total_customers,
    (SELECT COUNT(DISTINCT wr.returning_customer_sk) FROM web_returns wr WHERE wr.returned_date_sk = 20230101) AS total_web_returns,
    STRING_AGG(DISTINCT i.i_item_id) AS item_ids_above_threshold
FROM 
    ranked_sales rs
JOIN 
    customer_address ca ON rs.bill_customer_sk = ca.ca_address_sk
LEFT JOIN 
    customer_details cd ON rs.bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c WHERE c.c_current_cdemo_sk = cd.cd_demo_sk)
JOIN 
    item_sales is ON rs.bill_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales ws JOIN item i ON ws.ws_item_sk = i.i_item_sk WHERE is.total_quantity > 10)
WHERE 
    rs.rank_profit = 1
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT rs.ship_date_sk) > 5
ORDER BY 
    max_profit_per_city DESC;
