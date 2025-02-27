
WITH AddressStats AS (
    SELECT 
        ca_city,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        COUNT(DISTINCT CASE WHEN c_customer_sk IS NOT NULL THEN c_customer_sk END) AS distinct_customers,
        COUNT(DISTINCT c_customer_sk) FILTER (WHERE c_birth_year = 1990) AS customers_born_in_1990,
        ROW_NUMBER() OVER (PARTITION BY ca_city ORDER BY COUNT(DISTINCT c_customer_sk) DESC) AS city_rank
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca_city
),
SalesStats AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_ext_sales_price) AS total_sales,
        SUM(ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq
),
StockStats AS (
    SELECT 
        inv_date_sk,
        SUM(CASE WHEN inv_quantity_on_hand < 100 THEN inv_quantity_on_hand ELSE 0 END) AS low_stock,
        SUM(inv_quantity_on_hand) AS total_stock
    FROM 
        inventory
    GROUP BY 
        inv_date_sk
)
SELECT 
    a.ca_city,
    s.d_year,
    s.d_month_seq,
    s.total_sales,
    s.total_profit,
    s.total_orders,
    as.customer_count,
    as.customers_born_in_1990,
    st.low_stock,
    st.total_stock,
    CASE 
        WHEN as.city_rank = 1 THEN 'Top City'
        ELSE 'Other City'
    END AS city_status,
    INITCAP(REPLACE(a.ca_city, ' ', '_')) AS formatted_city_name,
    COALESCE(NULLIF(a.ca_city, ''), 'Unknown') AS safe_city_name
FROM 
    AddressStats as
JOIN 
    SalesStats s ON as.city_rank = 1
LEFT JOIN 
    StockStats st ON st.inv_date_sk = s.d_year
WHERE 
    s.total_sales > (SELECT AVG(total_sales) FROM SalesStats WHERE total_orders > 10)
ORDER BY 
    s.total_profit DESC, a.ca_city ASC;
