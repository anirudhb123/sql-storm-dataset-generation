
WITH RankedReturns AS (
    SELECT 
        wr.web_page_sk,
        wr.returned_date_sk,
        COUNT(wr.return_order_number) AS return_count,
        SUM(wr.return_amt) AS total_return_amt,
        SUM(wr.return_tax) AS total_return_tax,
        ROW_NUMBER() OVER (PARTITION BY wr.returned_date_sk ORDER BY COUNT(wr.return_order_number) DESC) AS rank
    FROM 
        web_returns wr
    JOIN 
        web_sales ws ON ws.ws_order_number = wr.return_order_number
    GROUP BY 
        wr.web_page_sk, wr.returned_date_sk
),
EnhancedCustomerMetrics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        d.d_year,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_sales_price ELSE 0 END) AS total_spent,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, d.d_year
),
TopReturnPages AS (
    SELECT 
        r.web_page_sk,
        r.return_count,
        r.total_return_amt,
        r.total_return_tax
    FROM 
        RankedReturns r
    WHERE 
        r.rank <= 5
)
SELECT 
    e.c_customer_sk,
    e.c_first_name,
    e.c_last_name,
    e.total_spent,
    e.total_orders,
    e.avg_order_value,
    t.return_count,
    t.total_return_amt,
    t.total_return_tax
FROM 
    EnhancedCustomerMetrics e
LEFT JOIN 
    TopReturnPages t ON t.web_page_sk = (SELECT TOP 1 web_page_sk FROM TopReturnPages ORDER BY return_count DESC)
ORDER BY 
    e.total_spent DESC;
