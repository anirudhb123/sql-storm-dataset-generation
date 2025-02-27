
WITH address_summary AS (
    SELECT
        ca_city,
        ca_state,
        COUNT(*) AS total_addresses,
        STRING_AGG(ca_street_name, ', ') AS street_names,
        STRING_AGG(ca_street_type, ', ') AS street_types
    FROM
        customer_address
    GROUP BY
        ca_city, ca_state
),
customer_purchases AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id
),
ranked_customers AS (
    SELECT
        c.c_customer_id,
        cp.total_spent,
        RANK() OVER (ORDER BY cp.total_spent DESC) AS customer_rank
    FROM
        customer_purchases cp
    JOIN
        customer c ON cp.c_customer_id = c.c_customer_id
    WHERE
        cp.total_spent > 0
),
selected_customers AS (
    SELECT 
        rc.c_customer_id,
        rc.total_spent,
        rc.customer_rank,
        address_summary.ca_city,
        address_summary.ca_state,
        address_summary.total_addresses
    FROM
        ranked_customers rc
    JOIN
        address_summary ON address_summary.ca_city IN (
            SELECT ca_city FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk
        ) AND address_summary.ca_state = (
            SELECT ca_state FROM customer_address WHERE ca_address_sk = c.c_current_addr_sk
        )
    WHERE
        rc.customer_rank <= 10
)
SELECT 
    sc.c_customer_id,
    sc.total_spent,
    sc.customer_rank,
    sc.ca_city,
    sc.ca_state,
    sc.total_addresses
FROM 
    selected_customers sc
ORDER BY 
    sc.customer_rank;
