
WITH RankedSales AS (
    SELECT 
        ws.web_site_id, 
        ws.web_name, 
        SUM(ws.ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id, ws.web_name
),
TopSales AS (
    SELECT * 
    FROM RankedSales 
    WHERE rank <= 5
),
ReturnedSales AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(wr.wr_order_number) AS return_count,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_return_tax) AS total_return_tax
    FROM 
        web_returns wr
    GROUP BY 
        wr.returning_customer_sk
)
SELECT 
    ts.web_site_id, 
    ts.web_name, 
    ts.total_sales, 
    COALESCE(rs.return_count, 0) AS return_count,
    COALESCE(rs.total_return_amount, 0) AS total_return_amount,
    COALESCE(rs.total_return_tax, 0) AS total_return_tax,
    ts.total_sales - COALESCE(rs.total_return_amount, 0) AS net_sales
FROM 
    TopSales ts
LEFT JOIN 
    ReturnedSales rs ON ts.web_site_id = rs.returning_customer_sk
ORDER BY 
    ts.total_sales DESC;
