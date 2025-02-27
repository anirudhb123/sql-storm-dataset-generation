
WITH AddressDetails AS (
    SELECT 
        ca.city AS address_city,
        ca.state AS address_state,
        COUNT(DISTINCT c.c_customer_id) AS customer_count,
        SUM(CASE 
            WHEN cd.cd_gender = 'M' THEN 1 ELSE 0 END) AS male_count,
        SUM(CASE 
            WHEN cd.cd_gender = 'F' THEN 1 ELSE 0 END) AS female_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer_address ca
    JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ca.city, ca.state
),
DateDetails AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_ext_tax) AS total_tax
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    GROUP BY d.d_year, d.d_month_seq
)
SELECT 
    ad.address_city,
    ad.address_state,
    ad.customer_count,
    ad.male_count,
    ad.female_count,
    ad.avg_purchase_estimate,
    dd.d_year,
    dd.d_month_seq,
    dd.total_orders,
    dd.total_sales,
    dd.total_tax
FROM AddressDetails ad
JOIN DateDetails dd ON ad.customer_count > 100
ORDER BY ad.address_state, ad.address_city, dd.d_year DESC, dd.d_month_seq;
