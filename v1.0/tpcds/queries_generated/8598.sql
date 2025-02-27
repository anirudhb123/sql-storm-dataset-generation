
WITH CustomerStatistics AS (
    SELECT 
        cd_gender,
        COUNT(DISTINCT c_customer_sk) AS customer_count,
        AVG(CASE WHEN cd_marital_status = 'M' THEN 1 ELSE 0 END) AS married_ratio,
        SUM(cd_dep_count) AS total_dependents,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer
    JOIN 
        customer_demographics ON c_current_cdemo_sk = cd_demo_sk
    GROUP BY 
        cd_gender
), 
SalesSummary AS (
    SELECT 
        ws_ship_date_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk
), 
SalesPerformance AS (
    SELECT 
        d.d_date AS sales_date,
        COALESCE(cs.total_quantity, 0) AS total_quantity,
        COALESCE(cs.total_sales, 0) AS total_sales,
        COUNT(DISTINCT cs.total_orders) AS total_orders,
        ROUND(SUM(CASE WHEN cs.total_quantity > 0 THEN cs.total_sales ELSE 0 END), 2) AS net_sales
    FROM 
        date_dim d
    LEFT JOIN 
        SalesSummary cs ON d.d_date_sk = cs.ws_ship_date_sk
    GROUP BY 
        d.d_date
)
SELECT 
    a.cd_gender,
    a.customer_count,
    a.married_ratio,
    a.total_dependents,
    b.sales_date,
    b.total_quantity,
    b.total_sales,
    b.total_orders,
    b.net_sales
FROM 
    CustomerStatistics a
JOIN 
    SalesPerformance b ON a.customer_count > 0
ORDER BY 
    b.sales_date DESC, 
    a.cd_gender;
