
WITH AddressCounts AS (
    SELECT 
        ca_city, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count, 
        SUM(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_count,
        AVG(COALESCE(cd_purchase_estimate, 0)) AS avg_purchase_estimate
    FROM 
        customer_address ca
    LEFT JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_city
), 
SalesData AS (
    SELECT
        d.d_year,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        d.d_year, ws.web_site_id
),
RankedSales AS (
    SELECT 
        d_year,
        web_site_id,
        total_quantity,
        total_sales,
        total_orders,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    ac.ca_city,
    ac.customer_count,
    ac.married_count,
    ac.avg_purchase_estimate,
    rs.total_quantity,
    rs.total_sales,
    rs.total_orders,
    CASE 
        WHEN rs.sales_rank = 1 THEN 'Top Seller'
        WHEN rs.sales_rank <= 5 THEN 'High Seller'
        ELSE 'Regular Seller'
    END AS sales_category
FROM 
    AddressCounts ac
LEFT JOIN 
    RankedSales rs ON ac.customer_count > 0 AND rs.total_orders IS NOT NULL
WHERE 
    ac.avg_purchase_estimate IS NOT NULL
    AND (SELECT COUNT(*) FROM customer c WHERE c.c_current_addr_sk IS NOT NULL) > 1000
ORDER BY 
    ac.ca_city, rs.d_year DESC, rs.sales_category;
