
WITH customer_sales AS (
    SELECT 
        c.c_customer_id,
        SUM(COALESCE(ws.ws_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ss.ss_net_profit, 0)) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_count,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_order_count,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_order_count
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_id
),
top_customers AS (
    SELECT 
        c.c_customer_id AS customer_id,
        cs.total_profit,
        cs.web_order_count,
        cs.catalog_order_count,
        cs.store_order_count,
        RANK() OVER (ORDER BY cs.total_profit DESC) AS profit_rank
    FROM 
        customer_sales cs
    JOIN 
        (SELECT 
            c_customer_id 
         FROM 
            customer 
         WHERE 
            c_birth_year IS NOT NULL
        ) c ON cs.c_customer_id = c.c_customer_id
),
high_value_customers AS (
    SELECT 
        tc.*, 
        (web_order_count + catalog_order_count + store_order_count) AS total_orders,
        CASE 
            WHEN total_profit > 1000 THEN 'High Value'
            WHEN total_profit BETWEEN 500 AND 1000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS customer_segment
    FROM 
        top_customers tc
    WHERE 
        profit_rank <= 10
)
SELECT 
    hvc.customer_id,
    hvc.total_profit,
    hvc.total_orders,
    hvc.customer_segment,
    (SELECT COUNT(DISTINCT sr_ticket_number) 
     FROM store_returns 
     WHERE sr_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = hvc.customer_id)
    ) AS return_count,
    (SELECT COUNT(DISTINCT wr_order_number) 
     FROM web_returns 
     WHERE wr_returning_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = hvc.customer_id)
    ) AS web_return_count,
    (SELECT COUNT(DISTINCT cr_order_number) 
     FROM catalog_returns 
     WHERE cr_returning_customer_sk = (SELECT c_customer_sk FROM customer WHERE c_customer_id = hvc.customer_id)
    ) AS catalog_return_count
FROM 
    high_value_customers hvc
WHERE 
    hvc.total_orders > 5
ORDER BY 
    hvc.total_profit DESC;
