
WITH AddressDetails AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        LISTAGG(DISTINCT c.c_first_name || ' ' || c.c_last_name, ', ') AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city, ca.ca_state, ca.ca_country
),
SalesDetails AS (
    SELECT 
        d.d_year,
        sm.sm_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        d.d_year, sm.sm_type
),
CombinedDetails AS (
    SELECT 
        ad.ca_city,
        ad.ca_state,
        ad.ca_country,
        ad.customer_count,
        ad.customer_names,
        sd.d_year,
        sd.sm_type,
        sd.total_quantity,
        sd.total_net_profit
    FROM 
        AddressDetails ad
    FULL JOIN 
        SalesDetails sd ON ad.ca_state = sd.sm_type
)
SELECT 
    ca_city,
    ca_state,
    ca_country,
    customer_count,
    customer_names,
    d_year,
    sm_type,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_net_profit, 0) AS total_net_profit
FROM 
    CombinedDetails
ORDER BY 
    ca_state, d_year, sm_type;
