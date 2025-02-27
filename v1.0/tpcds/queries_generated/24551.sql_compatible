
WITH RECURSIVE revenue_cte AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER(PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        item i ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        i.i_current_price IS NOT NULL
    GROUP BY 
        ws.ws_item_sk
), high_value_items AS (
    SELECT 
        r.ws_item_sk, 
        r.total_sales
    FROM 
        revenue_cte r
    WHERE 
        r.sales_rank <= 10
), customer_summary AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE 
            WHEN COUNT(DISTINCT ws.ws_order_number) = 0 THEN 'No Orders'
            ELSE 'Active Customer'
        END AS customer_status
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
), top_customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.order_count,
        cs.total_profit,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        customer_summary cs
    WHERE 
        cs.customer_status = 'Active Customer'
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    th.order_count,
    th.total_profit,
    hv.total_sales
FROM 
    top_customers th
JOIN 
    customer c ON c.c_customer_sk = th.c_customer_sk
LEFT JOIN 
    high_value_items hv ON hv.ws_item_sk IN (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = c.c_customer_sk)
WHERE 
    th.profit_rank <= 5
ORDER BY 
    th.total_profit DESC,
    c.c_last_name ASC
LIMIT 10
OFFSET 5;
