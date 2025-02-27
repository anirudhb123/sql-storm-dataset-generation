
WITH SalesData AS (
    SELECT 
        ws.ws_order_number, 
        ws.ws_quantity,
        ws.ws_net_paid,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        i.i_category,
        SUM(ws.ws_net_paid) OVER(PARTITION BY ca.ca_city, d.d_year, i.i_category) AS total_sales_city_category_year
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20220101 AND 20221231
),
RankedSales AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY ca_city, d_year ORDER BY total_sales_city_category_year DESC) AS sales_rank
    FROM 
        SalesData
)
SELECT 
    ca.ca_city, 
    d.d_year,
    i.i_category, 
    COUNT(DISTINCT ws_order_number) AS order_count,
    AVG(ws_quantity) AS avg_quantity_per_order,
    SUM(ws_net_paid) AS total_sales,
    MAX(total_sales_city_category_year) AS max_sales_in_category
FROM 
    RankedSales
WHERE 
    sales_rank <= 5
GROUP BY 
    ca.ca_city, d.d_year, i.i_category
ORDER BY 
    ca.ca_city, d.d_year, total_sales DESC;
