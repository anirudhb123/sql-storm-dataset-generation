
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws_item_sk
),
CustomerAddressCTE AS (
    SELECT 
        ca_address_sk,
        ca_city,
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_address_sk, ca_city, ca_state
),
SalesWithRank AS (
    SELECT 
        s.*,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sale_rank
    FROM 
        web_sales s
    JOIN 
        SalesCTE st ON s.ws_item_sk = st.ws_item_sk
    WHERE 
        st.total_net_paid > 1000
)
SELECT 
    c.c_customer_id,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COALESCE(ca.ca_state, 'Unknown') AS state,
    s.total_quantity,
    s.total_net_paid,
    CASE 
        WHEN ca.ca_city IS NULL AND ca.ca_state IS NULL THEN 'N/A' 
        ELSE 'Exists' 
    END AS address_status
FROM 
    customer c
LEFT JOIN 
    CustomerAddressCTE ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    SalesWithRank s ON c.c_customer_sk = s.ws_bill_customer_sk
WHERE 
    s.sale_rank = 1
    AND (c.c_birth_year IS NULL OR c.c_birth_year > 1990)
    OR EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk IN (
            SELECT sr_store_sk 
            FROM store_returns 
            WHERE sr_returned_date_sk IS NOT NULL AND sr_return_amount > 0
        )
    )
ORDER BY 
    total_net_paid DESC, 
    city ASC 
LIMIT 100 OFFSET 10;
