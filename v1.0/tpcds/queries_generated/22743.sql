
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sales_price IS NOT NULL AND
        ws.ws_quantity > 0
),
TotalSales AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned_quantity,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT w.ws_order_number) AS total_orders,
        AVG(COALESCE(cd.cd_dep_count, 0)) AS average_dependencies
    FROM 
        customer c 
    LEFT JOIN 
        web_sales w ON c.c_customer_sk = w.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_city,
    COALESCE(SUM(rs.ws_quantity), 0) AS total_sold,
    MAX(ts.total_returned_quantity) AS max_returned_quantity,
    MIN(ts.total_return_amount) AS min_return_amount,
    COUNT(DISTINCT cs.c_customer_sk) AS unique_customers,
    STRING_AGG(DISTINCT CASE WHEN cs.total_orders > 5 THEN 'Frequent Buyer' ELSE 'Occasional Buyer' END, ', ') AS customer_type
FROM 
    customer_address ca
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = ca.ca_address_sk
LEFT JOIN 
    TotalSales ts ON ts.wr_item_sk = rs.ws_item_sk
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = rs.ws_order_number
WHERE 
    ca.ca_state IN ('CA', 'NY')
    AND (ts.total_returned_quantity IS NULL OR ts.total_returned_quantity < 10)
GROUP BY 
    ca.ca_city
HAVING 
    COUNT(DISTINCT cs.c_customer_sk) > 0
ORDER BY 
    total_sold DESC, 
    ca.ca_city
LIMIT 100;
