
WITH SalesData AS (
    SELECT 
        s.s_store_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MIN(d.d_date) AS first_sale_date,
        MAX(d.d_date) AS last_sale_date
    FROM 
        web_sales ws
    JOIN 
        store s ON ws.ws_store_sk = s.s_store_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        s.s_store_id
),
CustomerData AS (
    SELECT 
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca.ca_country
)
SELECT 
    sd.s_store_id,
    cd.ca_country,
    sd.total_quantity,
    sd.total_sales,
    sd.total_orders,
    cd.customer_count,
    cd.total_purchase_estimate,
    DATEDIFF(sd.last_sale_date, sd.first_sale_date) AS sales_duration_days
FROM 
    SalesData sd
JOIN 
    CustomerData cd ON sd.s_store_id = cd.ca_country
ORDER BY 
    sd.total_sales DESC, cd.customer_count DESC;
