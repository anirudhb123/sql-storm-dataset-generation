
WITH SalesSummary AS (
    SELECT 
        w.warehouse_name,
        SUM(ws.ext_sales_price - ws.ext_discount_amt) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.ext_sales_price) AS average_order_value,
        DENSE_RANK() OVER (PARTITION BY w.warehouse_name ORDER BY SUM(ws.ext_sales_price - ws.ext_discount_amt) DESC) AS sales_rank
    FROM 
        web_sales ws 
    JOIN 
        warehouse w ON ws.warehouse_sk = w.warehouse_sk 
    WHERE 
        ws.sold_date_sk BETWEEN (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 30 
                          AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        w.warehouse_name
), CustomerPreference AS (
    SELECT 
        c.customer_id,
        cd.gender,
        COUNT(ws.order_number) AS total_orders,
        SUM(ws.ext_sales_price) AS total_spent,
        CASE 
            WHEN SUM(ws.ext_sales_price) > 1000 THEN 'High'
            WHEN SUM(ws.ext_sales_price) BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS spending_category
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.current_cdemo_sk = cd.demo_sk
    LEFT JOIN 
        web_sales ws ON c.customer_sk = ws.bill_customer_sk 
    GROUP BY 
        c.customer_id, cd.gender
), ReturnAnalysis AS (
    SELECT 
        wr.returning_customer_sk,
        COUNT(wr.return_number) AS total_returns,
        SUM(wr.return_amt) AS total_returned_value,
        AVG(wr.return_quantity) AS average_return_quantity
    FROM 
        web_returns wr 
    GROUP BY 
        wr.returning_customer_sk
)
SELECT 
    cs.customer_id,
    cs.gender,
    SUM(cs.total_spent) AS lifetime_spending,
    COALESCE(ra.total_returns, 0) AS total_returns,
    COALESCE(ra.total_returned_value, 0) AS total_returned_value,
    COALESCE(ra.average_return_quantity, 0) AS average_return_quantity,
    ss.warehouse_name,
    ss.total_sales,
    ss.total_orders,
    ss.average_order_value,
    ss.sales_rank
FROM 
    CustomerPreference cs
LEFT JOIN 
    ReturnAnalysis ra ON cs.customer_id = ra.returning_customer_sk
JOIN 
    SalesSummary ss ON ss.total_sales > 1000
WHERE 
    (cs.spending_category = 'High' OR cs.total_orders > 5)
GROUP BY 
    cs.customer_id, cs.gender, ra.total_returns, ra.total_returned_value, 
    ra.average_return_quantity, ss.warehouse_name, ss.total_sales, 
    ss.total_orders, ss.average_order_value, ss.sales_rank
ORDER BY 
    lifetime_spending DESC, total_orders DESC;
