
WITH RankedSales AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        ca.ca_city,
        cd.cd_demo_sk,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_web_page_sk) AS total_web_visits,
        MAX(ws.ws_sales_price) AS max_order_amount,
        MIN(ws.ws_sales_price) AS min_order_amount
    FROM 
        customer c
        LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
        LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        cd.cd_gender = 'F' AND 
        (ca.ca_city IS NOT NULL OR ca.ca_city <> '') 
    GROUP BY 
        c.c_customer_sk, ca.ca_city, cd.cd_demo_sk
),
ReturnStats AS (
    SELECT 
        cr_item_sk,
        SUM(cr_return_quantity) AS total_returns,
        SUM(cr_return_amt) AS total_return_value
    FROM 
        catalog_returns
    WHERE 
        cr_return_quantity > 0
    GROUP BY 
        cr_item_sk
)
SELECT 
    r.ws_item_sk,
    r.total_quantity,
    r.total_sales,
    COALESCE(cs.total_orders, 0) AS total_customer_orders,
    COALESCE(cs.total_web_visits, 0) AS total_web_visits,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_value, 0.00) AS total_return_value,
    CASE 
        WHEN r.total_sales > 10000 THEN 'High Revenue'
        WHEN r.total_sales BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    RankedSales r
LEFT JOIN 
    CustomerStats cs ON r.ws_item_sk = cs.c_customer_sk 
LEFT JOIN 
    ReturnStats rs ON r.ws_item_sk = rs.cr_item_sk
WHERE 
    r.sales_rank = 1
ORDER BY 
    r.total_sales DESC,
    r.total_quantity DESC
LIMIT 50;
