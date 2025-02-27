
WITH RECURSIVE customer_rank AS (
    SELECT 
        c.c_customer_sk, 
        c.c_first_name, 
        c.c_last_name, 
        cd.cd_gender, 
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        c.c_birth_year IS NOT NULL
),
sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_net_profit
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
item_sales AS (
    SELECT 
        i.i_item_sk,
        i.i_product_name,
        COALESCE(ss.total_quantity, 0) AS total_quantity,
        COALESCE(ss.total_net_profit, 0) AS total_net_profit,
        RANK() OVER (ORDER BY COALESCE(ss.total_net_profit, 0) DESC) AS item_rank
    FROM 
        item i
    LEFT JOIN 
        sales_summary ss ON i.i_item_sk = ss.ws_item_sk
    WHERE 
        (i.i_current_price > 0 OR i.i_wholesale_cost IS NULL)
),
high_value_customers AS (
    SELECT 
        cr.c_customer_sk, 
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer cr
    JOIN 
        web_sales ws ON cr.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        cr.c_customer_sk
    HAVING 
        SUM(ws.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales)
)
SELECT 
    c.c_first_name || ' ' || c.c_last_name AS customer_name,
    COALESCE(ic.total_quantity, 0) AS items_purchased,
    COALESCE(ic.total_net_profit, 0) AS total_net_profit,
    CASE 
        WHEN hr.rnk <= 5 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_category
FROM 
    customer_rank hr
LEFT JOIN 
    item_sales ic ON hr.c_customer_sk = ic.i_item_sk
WHERE 
    hr.rnk IS NOT NULL
AND 
    hr.c_customer_sk IN (SELECT c.c_customer_sk FROM high_value_customers c)
ORDER BY 
    items_purchased DESC, total_net_profit DESC;
