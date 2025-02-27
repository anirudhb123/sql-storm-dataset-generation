
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_item_sk, 
        ws_order_number, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number) AS row_num
    FROM web_sales
    WHERE ws_net_profit IS NOT NULL
),
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT cs_order_number) AS total_orders,
        SUM(COALESCE(cs_net_profit, 0)) AS total_net_profit,
        DENSE_RANK() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(cs_net_profit, 0)) DESC) AS profit_rank
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
popular_items AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws_quantity) AS total_sales_qty,
        SUM(ws_net_profit) AS total_profit
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_desc
    HAVING SUM(ws_quantity) > 1000
    ORDER BY total_sales_qty DESC
    LIMIT 5
)
SELECT 
    cd.c_first_name,
    cd.c_last_name,
    cd.cd_gender,
    SUM(sd.ws_net_profit) AS tot_profit,
    pi.i_item_desc,
    pi.total_sales_qty,
    pi.total_profit
FROM customer_data cd
LEFT JOIN sales_data sd ON cd.c_customer_sk = sd.ws_item_sk
JOIN popular_items pi ON sd.ws_item_sk = pi.i_item_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.total_orders > 10)
    OR
    (cd.cd_gender = 'M' AND cd.profit_rank < 4)
GROUP BY 
    cd.c_first_name, 
    cd.c_last_name, 
    cd.cd_gender, 
    pi.i_item_desc, 
    pi.total_sales_qty
HAVING 
    tot_profit > 500
ORDER BY 
    tot_profit DESC, 
    pi.total_profit DESC
OFFSET 5 ROWS
FETCH NEXT 10 ROWS ONLY;

SELECT DISTINCT 
    NULLIF(c.c_first_name, ' ') AS FirstName,
    COALESCE(dc.d_weekend, 'N/A') AS IsWeekend,
    ISNULL(i.i_item_desc, 'Unknown') AS ItemDescription
FROM customer c
LEFT OUTER JOIN date_dim dc ON dc.d_date_sk BETWEEN 1 AND 31
LEFT JOIN item i ON i.i_item_sk = (SELECT TOP 1 ws_item_sk FROM web_sales WHERE ws_order_number = ANY (SELECT ws_order_number FROM web_sales WHERE ws_bill_customer_sk = c.c_customer_sk) ORDER BY ws_net_profit DESC)
WHERE 
    c.c_last_name IS NOT NULL 
AND 
    (c.c_first_name LIKE '%e%' OR c.c_last_name LIKE '%a%')
ORDER BY 
    i.i_item_desc DESC;
