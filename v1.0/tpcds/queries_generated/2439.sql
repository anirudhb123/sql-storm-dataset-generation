
WITH RankedSales AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        DENSE_RANK() OVER (PARTITION BY ca_state ORDER BY SUM(ws.ws_net_paid) DESC) AS rank_within_state
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        c.c_customer_id, ca_state
),
HighSpenders AS (
    SELECT 
        r.c_customer_id,
        r.total_orders,
        r.total_spent
    FROM 
        RankedSales r
    WHERE 
        r.total_spent > (
            SELECT 
                AVG(total_spent) 
            FROM 
                RankedSales
        )
)
SELECT 
    h.c_customer_id,
    h.total_orders,
    h.total_spent,
    case 
        when h.total_orders > 10 then 'Frequent Buyer'
        when h.total_orders BETWEEN 5 AND 10 then 'Moderate Buyer'
        else 'Occasional Buyer'
    end AS buyer_category
FROM 
    HighSpenders h
JOIN 
    (SELECT DISTINCT ca_state FROM customer_address) ca 
    ON h.c_customer_id IS NOT NULL
WHERE 
    h.total_spent IS NOT NULL
ORDER BY 
    h.total_spent DESC
LIMIT 100;
