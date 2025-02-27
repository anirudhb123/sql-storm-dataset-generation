
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_order_value,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
    FROM 
        web_sales ws
    LEFT JOIN 
        catalog_sales cs ON ws.ws_order_number = cs.cs_order_number
    WHERE 
        ws.ws_sold_date_sk BETWEEN 50000 AND 60000
    GROUP BY 
        ws.web_site_id
),
CustomerAnalytics AS (
    SELECT 
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(cd.cd_dep_count) AS total_dependents
    FROM 
        customer c
    INNER JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    INNER JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IN ('CA', 'NY')
    GROUP BY 
        ca.ca_city, ca.ca_state
),
ReturnReasons AS (
    SELECT 
        cr.cr_reason_sk,
        COUNT(*) AS return_count,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.cr_reason_sk
)
SELECT 
    sa.web_site_id,
    sa.total_sales,
    sa.total_orders,
    ca.city,
    ca.state,
    ca.customer_count,
    ca.avg_purchase_estimate,
    rr.return_count,
    rr.total_return_amount,
    AVG(CASE 
            WHEN rr.return_count > 5 THEN rr.total_return_amount * 1.05
            ELSE rr.total_return_amount 
        END) AS adjusted_return_amount,
    RANK() OVER (PARTITION BY ca.ca_state ORDER BY sa.total_sales DESC) AS sales_rank
FROM 
    SalesData sa
JOIN 
    CustomerAnalytics ca ON 1=1
LEFT JOIN 
    ReturnReasons rr ON rr.cr_reason_sk = (SELECT MIN(cr_reason_sk) FROM ReturnReasons)
WHERE 
    sa.total_sales > 1000
ORDER BY 
    sa.total_sales DESC, ca.city;
