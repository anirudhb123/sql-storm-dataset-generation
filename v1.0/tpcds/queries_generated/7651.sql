
WITH SalesData AS (
    SELECT 
        ws.sold_date_sk,
        ws.web_site_sk,
        ws.order_number,
        SUM(ws.ext_sales_price) AS total_sales,
        SUM(ws.ext_discount_amt) AS total_discount,
        COUNT(DISTINCT ws.bill_customer_sk) AS unique_customers,
        AVG(ws.net_profit) AS average_profit
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.sold_date_sk = dd.d_date_sk
    JOIN 
        web_site w ON ws.web_site_sk = w.web_site_sk
    WHERE 
        dd.d_year = 2023 AND
        w.web_class = 'B2C'
    GROUP BY 
        ws.sold_date_sk, 
        ws.web_site_sk, 
        ws.order_number
),
AggregatedSales AS (
    SELECT 
        sold_date_sk,
        web_site_sk,
        SUM(total_sales) AS total_revenue,
        SUM(total_discount) AS total_discounted_revenue,
        SUM(unique_customers) AS total_unique_customers,
        AVG(average_profit) AS overall_average_profit
    FROM 
        SalesData
    GROUP BY 
        sold_date_sk, 
        web_site_sk
)
SELECT 
    dd.d_date AS report_date,
    w.web_name AS website,
    as.total_revenue,
    as.total_discounted_revenue,
    as.total_unique_customers,
    as.overall_average_profit
FROM 
    AggregatedSales as
JOIN 
    date_dim dd ON as.sold_date_sk = dd.d_date_sk
JOIN 
    web_site w ON as.web_site_sk = w.web_site_sk
ORDER BY 
    dd.d_date, 
    w.web_name;
