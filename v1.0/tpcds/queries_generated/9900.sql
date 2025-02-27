
WITH SalesSummary AS (
    SELECT 
        d.d_year AS sales_year, 
        d.d_month_seq AS sales_month,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        c.cd_gender AS customer_gender,
        ca.ca_city AS customer_city
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        d.d_year, d.d_month_seq, c.cd_gender, ca.ca_city
),
RankedSales AS (
    SELECT 
        sales_year, 
        sales_month, 
        total_quantity_sold, 
        total_sales_amount, 
        total_orders, 
        avg_sales_price,
        customer_gender,
        customer_city,
        RANK() OVER (PARTITION BY sales_year, sales_month ORDER BY total_sales_amount DESC) AS sales_rank
    FROM 
        SalesSummary
)
SELECT 
    sales_year,
    sales_month,
    customer_gender,
    customer_city,
    total_quantity_sold,
    total_sales_amount,
    total_orders,
    avg_sales_price
FROM 
    RankedSales
WHERE 
    sales_rank <= 3
ORDER BY 
    sales_year, sales_month, total_sales_amount DESC;
