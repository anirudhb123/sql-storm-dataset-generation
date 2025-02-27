
WITH RECURSIVE SalesTrend AS (
    SELECT 
        ws_sold_date_sk,
        SUM(ws_net_paid) AS TotalSales,
        ROW_NUMBER() OVER (ORDER BY ws_sold_date_sk) AS SalesRank
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk
    HAVING 
        SUM(ws_net_paid) > 1000
    UNION ALL
    SELECT 
        ws.sold_date_sk,
        SUM(ws.ws_net_paid) + st.TotalSales AS TotalSales,
        ROW_NUMBER() OVER (ORDER BY ws.sold_date_sk) AS SalesRank
    FROM 
        web_sales ws
    JOIN 
        SalesTrend st ON ws.ws_sold_date_sk = st.ws_sold_date_sk + 1
    GROUP BY 
        ws.sold_date_sk, st.TotalSales
),
TopSales AS (
    SELECT 
        ca_county,
        SUM(ws_ext_sales_price) AS county_total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count,
        DENSE_RANK() OVER (PARTITION BY ca_county ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM 
        web_sales
    JOIN 
        customer c ON ws_ship_customer_sk = c.c_customer_sk
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    GROUP BY 
        ca_county
),
BestCounties AS (
    SELECT 
        ca_county,
        county_total_sales,
        order_count
    FROM 
        TopSales
    WHERE 
        rank <= 3
),
DateFilter AS (
    SELECT 
        d_date_sk,
        d_year,
        d_month_seq,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        date_dim dd
    JOIN 
        web_sales ws ON dd.d_date_sk = ws.ws_sold_date_sk
    WHERE 
        d_year = 2023 AND d_month_seq IN (7, 8, 9)
    GROUP BY 
        d_date_sk, d_year, d_month_seq
)
SELECT 
    b.ca_county,
    b.county_total_sales,
    b.order_count,
    df.d_year,
    SUM(df.order_count) AS total_orders,
    AVG(Trend.TotalSales) AS average_sales
FROM 
    BestCounties b
LEFT JOIN 
    DateFilter df ON b.order_count = df.order_count
LEFT JOIN 
    SalesTrend Trend ON df.d_date_sk = Trend.ws_sold_date_sk
WHERE 
    b.county_total_sales IS NOT NULL
GROUP BY 
    b.ca_county, b.county_total_sales, b.order_count, df.d_year
HAVING 
    AVG(Trend.TotalSales) > 5000
ORDER BY 
    total_orders DESC, b.county_total_sales DESC;
