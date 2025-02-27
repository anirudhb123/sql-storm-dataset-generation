
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        count(ws.ws_order_number) AS total_orders,
        sum(ws.ws_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT ws.ws_ship_customer_sk) AS unique_customers,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY sum(ws.ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        dd.d_year = 2023 
        AND dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.web_site_id
),
TopSites AS (
    SELECT 
        ws.web_site_id,
        total_orders,
        total_sales,
        avg_net_profit,
        unique_customers
    FROM 
        SalesData
    WHERE 
        sales_rank <= 5
)
SELECT 
    ts.web_site_id,
    ts.total_orders,
    ts.total_sales,
    ts.avg_net_profit,
    ts.unique_customers,
    ca.ca_country,
    c.cd_gender,
    cd.cd_marital_status
FROM 
    TopSites ts
JOIN 
    web_site w ON ts.web_site_id = w.web_site_id
JOIN 
    customer_address ca ON w.web_company_id = ca.ca_address_sk
JOIN 
    customer_demographics cd ON ts.unique_customers = cd.cd_demo_sk
ORDER BY 
    total_sales DESC;
