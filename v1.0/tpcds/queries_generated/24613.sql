
WITH ranked_sales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND
        ws.ws_quantity > 0
),
item_details AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned, 
        COUNT(DISTINCT ss.ss_ticket_number) AS total_sales
    FROM 
        item i
    LEFT JOIN 
        store_sales ss ON i.i_item_sk = ss.ss_item_sk
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_desc, i.i_current_price, i.i_brand
),
high_value_customers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_first_shipto_date_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
    HAVING 
        total_spent > 10000
),
sales_summary AS (
    SELECT 
        item.i_item_desc,
        item.i_current_price,
        customer.c_customer_sk,
        customer.c_first_name,
        COUNT(sales.ws_order_number) AS order_count,
        SUM(sales.ws_net_profit) AS total_profit
    FROM 
        item_details item
    JOIN 
        web_sales sales ON item.i_item_sk = sales.ws_item_sk
    JOIN 
        high_value_customers customer ON sales.ws_bill_customer_sk = customer.c_customer_sk
    WHERE 
        sales.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = EXTRACT(YEAR FROM CURRENT_DATE) - 1) 
    GROUP BY 
        item.i_item_desc, item.i_current_price, customer.c_customer_sk, customer.c_first_name
)
SELECT 
    summary.i_item_desc,
    summary.i_current_price,
    summary.c_customer_sk,
    summary.c_first_name,
    summary.order_count,
    summary.total_profit,
    COALESCE(ranked_sales.sales_rank, 0) AS item_rank,
    CASE 
        WHEN summary.total_profit > 5000 THEN 'High Profit'
        WHEN summary.total_profit BETWEEN 2000 AND 5000 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    sales_summary summary
LEFT JOIN 
    ranked_sales ON summary.i_item_desc = (SELECT i_item_desc FROM item WHERE i_item_sk = ranked_sales.ws_item_sk) 
ORDER BY 
    summary.total_profit DESC, 
    summary.i_item_desc;
