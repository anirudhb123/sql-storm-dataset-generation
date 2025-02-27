
WITH RECURSIVE customer_spend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
), 
top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        DENSE_RANK() OVER (ORDER BY cs.total_spent DESC) AS rank
    FROM 
        customer_spend cs
    WHERE 
        cs.rank = 1
),
inventory_summary AS (
    SELECT 
        i.i_item_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory
    FROM 
        inventory i
    GROUP BY 
        i.i_item_sk
),
returns_summary AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
sales_returns AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_net_profit) - COALESCE(SUM(rs.total_returns), 0) AS net_profit_after_returns
    FROM 
        web_sales ws
    LEFT JOIN 
        returns_summary rs ON ws.ws_item_sk = rs.wr_item_sk
    GROUP BY 
        ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.total_spent,
    inv.total_inventory,
    COALESCE(sales.net_profit_after_returns, 0) AS net_profit
FROM 
    top_customers t
INNER JOIN 
    customer c ON t.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    inventory_summary inv ON inv.i_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
LEFT JOIN 
    sales_returns sales ON sales.ws_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    c.c_birth_year IS NOT NULL AND 
    (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
ORDER BY 
    net_profit DESC
LIMIT 10;
