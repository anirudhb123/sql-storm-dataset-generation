
WITH RECURSIVE sales_data AS (
    SELECT 
        ws_order_number, 
        ws_item_sk, 
        ws_quantity, 
        ws_ext_sales_price, 
        ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_order_number ORDER BY ws_net_profit DESC) as rank
    FROM 
        web_sales 
    WHERE 
        ws_sold_date_sk BETWEEN 2451915 AND 2452000
),
top_sales AS (
    SELECT 
        sd.ws_order_number,
        SUM(sd.ws_quantity) AS total_quantity, 
        SUM(sd.ws_ext_sales_price) AS total_sales, 
        SUM(sd.ws_net_profit) AS total_profit
    FROM 
        sales_data sd
    WHERE 
        sd.rank <= 3
    GROUP BY 
        sd.ws_order_number
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_dow,
        SUM(sd.total_quantity) AS total_quantity,
        SUM(sd.total_sales) AS total_sales,
        SUM(sd.total_profit) AS total_profit
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        top_sales sd ON sd.ws_order_number IN (
            SELECT w.ws_order_number 
            FROM web_sales w 
            WHERE w.ws_bill_customer_sk = c.c_customer_sk
        )
    JOIN 
        date_dim d ON d.d_date_sk = sd.ws_sold_date_sk
    WHERE 
        cd.cd_gender = 'F' AND
        cd.cd_marital_status = 'M'
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_dow
),
final_report AS (
    SELECT 
        ci.c_first_name,
        ci.c_last_name,
        ci.total_quantity,
        ci.total_sales,
        ci.total_profit,
        CASE 
            WHEN ci.total_profit IS NULL THEN 'No Profit'
            ELSE 'Profit Achieved' 
        END AS profit_status
    FROM 
        customer_info ci
    WHERE 
        ci.total_sales > (SELECT AVG(total_sales) FROM customer_info)
)
SELECT 
    fr.c_first_name,
    fr.c_last_name,
    fr.total_quantity,
    fr.total_sales,
    fr.total_profit,
    fr.profit_status
FROM 
    final_report fr
ORDER BY 
    fr.total_profit DESC;
