
WITH StringAggregation AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ca.ca_city || ', ' || ca.ca_state AS full_address,
        COUNT(ws.ws_order_number) AS order_count,
        SUM(ws.ws_net_paid) AS total_spent,
        STRING_AGG(DISTINCT c.c_email_address, ', ') AS email_list
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ca.ca_city, ca.ca_state
),
RankedCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank_by_spending
    FROM 
        StringAggregation
)
SELECT 
    rank_by_spending,
    full_name,
    full_address,
    order_count,
    total_spent,
    email_list
FROM 
    RankedCustomers
WHERE 
    rank_by_spending <= 10
ORDER BY 
    rank_by_spending;
