
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        d.d_year,
        SUM(ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders,
        COUNT(DISTINCT ws_bill_customer_sk) AS unique_customers
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY 
        ws.web_site_id, d.d_year
),
RefundSummary AS (
    SELECT 
        wr.web_site_id,
        d.d_year,
        SUM(wr_return_amt) AS total_refunds,
        COUNT(wr.order_number) AS total_refund_orders
    FROM 
        web_returns wr
    JOIN 
        date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN 
        web_sales ws ON wr.wr_order_number = ws.ws_order_number
    GROUP BY 
        wr.web_site_id, d.d_year
),
SalesAndRefunds AS (
    SELECT 
        ss.web_site_id,
        ss.d_year,
        total_sales,
        total_orders,
        unique_customers,
        COALESCE(rs.total_refunds, 0) AS total_refunds,
        COALESCE(rs.total_refund_orders, 0) AS total_refund_orders
    FROM 
        SalesSummary ss
    LEFT JOIN 
        RefundSummary rs ON ss.web_site_id = rs.web_site_id AND ss.d_year = rs.d_year
)
SELECT 
    web_site_id,
    d_year,
    total_sales,
    total_orders,
    unique_customers,
    total_refunds,
    total_refund_orders,
    (total_sales - total_refunds) AS net_sales,
    (total_sales / NULLIF(total_orders, 0)) AS avg_order_value,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_sales DESC) AS sales_rank
FROM 
    SalesAndRefunds
WHERE 
    (unique_customers > 100 OR total_orders > 50)
ORDER BY 
    d_year, sales_rank;
