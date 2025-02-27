
WITH RECURSIVE CustomerSpend AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL
    GROUP BY 
        c.c_customer_sk
    UNION ALL
    SELECT 
        cs.c_customer_sk,
        cs.total_spent + SUM(ws.ws_net_paid),
        cs.total_orders + COUNT(DISTINCT ws.ws_order_number)
    FROM 
        CustomerSpend cs
    JOIN 
        customer c ON cs.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cs.total_spent < 1000
    GROUP BY 
        cs.c_customer_sk
),
RankedCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.total_spent,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spend_rank
    FROM 
        CustomerSpend cs
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.c_email_address,
    rc.total_spent,
    rc.total_orders,
    rc.spend_rank,
    CASE 
        WHEN rc.total_orders IS NULL THEN 'N/A'
        WHEN rc.total_orders > 5 THEN 'Frequent Shopper'
        ELSE 'Occasional Shopper'
    END AS shopper_category
FROM 
    RankedCustomers rc
JOIN 
    customer c ON rc.c_customer_sk = c.c_customer_sk
WHERE 
    rc.spend_rank <= 10
ORDER BY 
    rc.spend_rank;
