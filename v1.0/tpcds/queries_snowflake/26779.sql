
WITH CustomerAddressSummary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        LISTAGG(DISTINCT CONCAT(c_first_name, ' ', c_last_name), '; ') WITHIN GROUP (ORDER BY c_first_name, c_last_name) AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca_state IN ('CA', 'TX', 'NY')
    GROUP BY 
        ca_state
),
SalesSummary AS (
    SELECT 
        d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        LISTAGG(DISTINCT CONCAT(sm_carrier, ' - ', sm_type), '; ') WITHIN GROUP (ORDER BY sm_carrier, sm_type) AS shipping_modes
    FROM 
        web_sales ws
    JOIN 
        ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        d_year = 2001
    GROUP BY 
        d_year
),
CombinedSummary AS (
    SELECT 
        cas.ca_state,
        cas.customer_count,
        cas.customer_names,
        ss.total_sales,
        ss.shipping_modes
    FROM 
        CustomerAddressSummary cas
    JOIN 
        SalesSummary ss ON TRUE 
)
SELECT 
    ca_state,
    customer_count,
    customer_names,
    total_sales,
    shipping_modes
FROM 
    CombinedSummary
ORDER BY 
    customer_count DESC;
