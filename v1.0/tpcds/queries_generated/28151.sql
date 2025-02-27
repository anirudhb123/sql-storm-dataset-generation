
WITH AddressDetails AS (
    SELECT 
        ca.city,
        ca.state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        STRING_AGG(DISTINCT CONCAT(c.c_first_name, ' ', c.c_last_name) ORDER BY c.c_last_name) AS customer_names
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state
),
SalesDetails AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        STRING_AGG(DISTINCT p.p_promo_name ORDER BY p.p_promo_name) AS promotion_names
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        d.d_year
),
CombinedDetails AS (
    SELECT 
        ad.city,
        ad.state,
        ad.customer_count,
        ad.customer_names,
        sd.d_year,
        sd.total_sales,
        sd.promotion_names
    FROM 
        AddressDetails ad
    JOIN 
        SalesDetails sd ON ad.city IS NOT NULL
)
SELECT 
    city,
    state,
    customer_count,
    customer_names,
    d_year,
    total_sales,
    promotion_names
FROM 
    CombinedDetails
ORDER BY 
    state, city, d_year;
