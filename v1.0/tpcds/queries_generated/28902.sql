
WITH RankedCustomAddresses AS (
    SELECT 
        ca.c_city,
        ca.ca_state,
        COUNT(c.c_customer_sk) AS customer_count,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY COUNT(c.c_customer_sk) DESC) AS state_rank
    FROM 
        customer_address ca
    JOIN 
        customer c ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.c_city, ca.ca_state
),
TopCities AS (
    SELECT 
        ca_state,
        c_city,
        customer_count
    FROM 
        RankedCustomAddresses
    WHERE 
        state_rank <= 3  -- Top 3 cities per state
)
SELECT 
    tc.ca_state,
    STRING_AGG(tc.c_city || ' (' || tc.customer_count || ')', '; ') AS Top_Cities
FROM 
    TopCities tc
GROUP BY 
    tc.ca_state
ORDER BY 
    tc.ca_state;
