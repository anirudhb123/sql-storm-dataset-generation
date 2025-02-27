
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id, 
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        a.ca_city,
        a.ca_state,
        d.d_year,
        d.d_month_seq,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_net_paid) AS total_spent,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c 
    JOIN 
        customer_address a ON c.c_current_addr_sk = a.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, a.ca_city, a.ca_state, d.d_year
),
Ranking AS (
    SELECT 
        c.*, 
        RANK() OVER (PARTITION BY c.ca_city, c.ca_state, c.d_year ORDER BY c.total_spent DESC) AS rank_spending
    FROM 
        CustomerInfo c
)
SELECT 
    r.full_name,
    r.ca_city,
    r.ca_state,
    r.d_year,
    r.total_orders,
    r.total_spent,
    r.avg_order_value,
    (SELECT COUNT(*) FROM Ranking r2 WHERE r2.ca_city = r.ca_city AND r2.ca_state = r.ca_state AND r2.d_year = r.d_year AND r2.rank_spending <= r.rank_spending) AS position_in_city
FROM 
    Ranking r
WHERE 
    r.rank_spending <= 10
ORDER BY 
    r.ca_city, r.ca_state, r.d_year, r.rank_spending;
