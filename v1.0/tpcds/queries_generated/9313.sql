
WITH SalesSummary AS (
    SELECT 
        d.d_year,
        c.cd_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, c.cd_gender
),
ReturnSummary AS (
    SELECT 
        d.d_year,
        c.cd_gender,
        SUM(wr.wr_return_amt_inc_tax) AS total_returns
    FROM 
        web_returns wr
    JOIN 
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN 
        customer c ON wr.wr_returning_customer_sk = c.c_customer_sk
    WHERE 
        d.d_year BETWEEN 2020 AND 2023
    GROUP BY 
        d.d_year, c.cd_gender
)

SELECT 
    ss.d_year,
    ss.cd_gender,
    ss.total_sales,
    ss.total_orders,
    ss.avg_order_value,
    COALESCE(rs.total_returns, 0) AS total_returns,
    (ss.total_sales - COALESCE(rs.total_returns, 0)) AS net_sales
FROM 
    SalesSummary ss
LEFT JOIN 
    ReturnSummary rs ON ss.d_year = rs.d_year AND ss.cd_gender = rs.cd_gender
ORDER BY 
    ss.d_year, ss.cd_gender;
