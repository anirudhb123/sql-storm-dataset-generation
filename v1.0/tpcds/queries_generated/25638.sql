
WITH CustomerAddress AS (
    SELECT 
        ca.city,
        ca.state,
        LOWER(CONCAT(ca.street_number, ' ', ca.street_name, ' ', ca.street_type)) AS full_address,
        COUNT(DISTINCT c.customer_sk) AS customer_count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.city, ca.state, full_address
),
DateRange AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        d.d_week_seq,
        COUNT(DISTINCT ws.web_order_number) AS total_sales
    FROM 
        date_dim d
    JOIN 
        web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY 
        d.d_year, d.d_month_seq, d.d_week_seq
),
AggregatedData AS (
    SELECT 
        ca.city,
        ca.state,
        ca.full_address,
        cr.customer_count,
        dr.total_sales
    FROM 
        CustomerAddress ca
    JOIN 
        DateRange dr ON ca.city = 'San Francisco' AND ca.state = 'CA'
)
SELECT 
    ad.city,
    ad.state,
    ad.full_address,
    ad.customer_count,
    ad.total_sales,
    CASE 
        WHEN ad.total_sales > 1000 THEN 'High Volume'
        WHEN ad.total_sales BETWEEN 500 AND 1000 THEN 'Medium Volume'
        ELSE 'Low Volume'
    END AS sales_volume_category
FROM 
    AggregatedData ad
WHERE 
    ad.customer_count > 0
ORDER BY 
    ad.total_sales DESC, ad.customer_count DESC;
