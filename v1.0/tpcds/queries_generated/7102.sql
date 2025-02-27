
WITH SalesData AS (
    SELECT 
        d.d_year,
        i.i_category,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_sales_price) AS average_sales_price
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY 
        d.d_year, i.i_category
),
RankedSales AS (
    SELECT 
        y.d_year,
        s.i_category,
        s.total_quantity,
        s.total_sales,
        s.average_sales_price,
        ROW_NUMBER() OVER (PARTITION BY s.i_category ORDER BY s.total_sales DESC) AS sales_rank
    FROM 
        SalesData s
    JOIN 
        date_dim y ON s.d_year = y.d_year
)
SELECT 
    rs.i_category,
    rs.total_quantity,
    rs.total_sales,
    rs.average_sales_price,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_purchase_estimate
FROM 
    RankedSales rs
JOIN 
    customer_demographics cd ON rs.sales_rank <= 10
ORDER BY 
    rs.i_category, rs.total_sales DESC;
