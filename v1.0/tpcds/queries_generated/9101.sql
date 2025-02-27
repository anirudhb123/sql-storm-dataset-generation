
WITH sales_summary AS (
    SELECT 
        d.d_year,
        c.c_gender,
        SUM(ws.ws_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit,
        COUNT(DISTINCT c.c_customer_id) AS unique_customers
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        d.d_year, c.c_gender
), return_summary AS (
    SELECT 
        d.d_year,
        SUM(wr.wr_return_amt) AS total_returns,
        COUNT(wr.wr_order_number) AS return_count
    FROM
        web_returns wr
    JOIN
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
), combined_summary AS (
    SELECT 
        s.d_year,
        s.c_gender,
        s.total_sales,
        s.order_count,
        s.avg_net_profit,
        s.unique_customers,
        r.total_returns,
        r.return_count
    FROM
        sales_summary s
    JOIN
        return_summary r ON s.d_year = r.d_year
)
SELECT 
    d_year,
    c_gender,
    total_sales,
    order_count,
    avg_net_profit,
    unique_customers,
    total_returns,
    return_count,
    (total_sales - total_returns) AS net_sales,
    (SELECT COUNT(*) FROM customer) AS total_customers_in_db
FROM
    combined_summary
ORDER BY
    d_year, c_gender;
