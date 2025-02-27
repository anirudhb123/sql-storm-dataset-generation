
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-01-01') 
                                AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2023-12-31')
),
SalesSummaries AS (
    SELECT 
        ca.ca_city,
        SUM(rs.ws_net_paid) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS order_count,
        COUNT(DISTINCT rs.ws_item_sk) AS unique_items,
        AVG(rs.ws_net_paid) AS avg_order_value
    FROM 
        customer_address ca
    LEFT JOIN 
        web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    LEFT JOIN 
        RankedSales rs ON ws.ws_order_number = rs.ws_order_number
    GROUP BY 
        ca.ca_city
),
TopCities AS (
    SELECT 
        ca.ca_city,
        SUM(rs.ws_net_paid) AS city_sales,
        RANK() OVER (ORDER BY SUM(rs.ws_net_paid) DESC) AS city_rank
    FROM 
        customer_address ca
    LEFT JOIN 
        web_sales ws ON ca.ca_address_sk = ws.ws_bill_addr_sk
    JOIN 
        RankedSales rs ON ws.ws_order_number = rs.ws_order_number
    GROUP BY 
        ca.ca_city
)
SELECT 
    sc.ca_city,
    ss.total_sales,
    ss.order_count,
    ss.unique_items,
    ss.avg_order_value,
    tc.city_rank
FROM 
    SalesSummaries ss
JOIN 
    TopCities tc ON ss.ca_city = tc.ca_city
WHERE 
    tc.city_rank <= 10
ORDER BY 
    tc.city_rank;
