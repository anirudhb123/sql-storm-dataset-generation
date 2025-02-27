
WITH RECURSIVE CTE_Totals AS (
    SELECT 
        ws_customer_sk,
        SUM(ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY ws_customer_sk ORDER BY SUM(ws_net_paid_inc_tax) DESC) AS rnk
    FROM 
        web_sales
    GROUP BY 
        ws_customer_sk
),
Customer_Sales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(ct.total_spent, 0) AS total_spent,
        COALESCE(ct.total_orders, 0) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        CTE_Totals ct ON c.c_customer_sk = ct.ws_customer_sk
),
Top_Customers AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        c.total_spent,
        c.total_orders,
        DENSE_RANK() OVER (ORDER BY c.total_spent DESC) as dense_rank
    FROM 
        Customer_Sales c
    WHERE 
        c.total_orders > 0
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    CASE 
        WHEN tc.dense_rank <= 10 THEN 'Top 10'
        ELSE 'Not Top 10'
    END AS customer_rank,
    (SELECT 
        SUM(ws_ext_discount_amt) 
     FROM 
        web_sales ws 
     WHERE 
        ws.ws_bill_customer_sk = tc.c_customer_id 
        AND ws.ws_sales_price > 100 
        AND ws.ws_sold_date_sk = (SELECT 
                                     MAX(d.d_date_sk) 
                                   FROM 
                                     date_dim d 
                                   WHERE 
                                     d.d_date BETWEEN '2023-01-01' AND '2023-12-31')
    ) AS total_high_value_discounts
FROM 
    Top_Customers tc
WHERE 
    EXISTS (
        SELECT 1 
        FROM customer_demographics cd 
        WHERE cd.cd_demo_sk = (SELECT c.c_current_cdemo_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_id)
        AND cd.cd_marital_status = 'M'
    )
ORDER BY 
    tc.total_spent DESC, 
    tc.c_last_name ASC NULLS FIRST
LIMIT 20
OFFSET 5;
