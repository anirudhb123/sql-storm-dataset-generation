
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_sales_price) DESC) AS rank_by_sales_value,
        MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price IS NOT NULL AND 
        (ws.ws_net_profit > 0 OR (ws.ws_quantity > 10 AND ws.ws_net_paid < 100))
    GROUP BY 
        ws.ws_item_sk
), 
customer_data AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    LEFT JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        (cd.cd_gender = 'F' AND cd.cd_marital_status = 'S') OR 
        (cd.cd_gender IS NULL AND cd.cd_marital_status IS NOT NULL)
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
), 
top_customers AS (
    SELECT 
        cd.c_customer_sk, 
        cd.c_first_name, 
        cd.c_last_name,
        cd.order_count
    FROM 
        customer_data AS cd
    WHERE 
        cd.order_count > (
            SELECT 
                AVG(order_count) 
            FROM 
                customer_data
        )
), 
item_returns AS (
    SELECT 
        sr.sr_item_sk,
        COUNT(sr.sr_ticket_number) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount
    FROM 
        store_returns AS sr
    GROUP BY 
        sr.sr_item_sk
)

SELECT 
    ir.sr_item_sk,
    ir.total_returns,
    ir.total_return_amount,
    rs.total_quantity,
    rs.last_sale_date,
    tc.c_first_name,
    tc.c_last_name
FROM 
    item_returns AS ir
JOIN 
    ranked_sales AS rs ON ir.sr_item_sk = rs.ws_item_sk
JOIN 
    top_customers AS tc ON ir.sr_item_sk IN (
        SELECT ws_item_sk FROM web_sales WHERE ws_bill_customer_sk = tc.c_customer_sk
    )
WHERE 
    (ir.total_returns > 5 OR rs.total_quantity < 20) AND 
    EXISTS (
        SELECT 1 
        FROM store_sales AS ss 
        WHERE ss.ss_item_sk = ir.sr_item_sk AND ss.ss_net_paid > 50
    )
ORDER BY 
    ir.total_return_amount DESC, 
    tc.c_last_name, 
    tc.c_first_name;
