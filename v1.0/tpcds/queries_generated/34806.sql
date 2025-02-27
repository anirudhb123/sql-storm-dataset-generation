
WITH RECURSIVE SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        ws_sold_date_sk,
        SUM(ws_sales_price * ws_quantity) AS total_sales,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk, ws_sold_date_sk
    UNION ALL
    SELECT 
        ss.web_site_sk,
        ss.ws_sold_date_sk + 1,
        SUM(ws_sales_price * ws_quantity) + ss.total_sales,
        COUNT(DISTINCT ws_order_number) + ss.order_count
    FROM 
        SalesSummary ss
    JOIN 
        web_sales ws ON ss.web_site_sk = ws.web_site_sk AND ws_sold_date_sk = ss.ws_sold_date_sk + 1
    WHERE 
        ss.ws_sold_date_sk < 30
),
CustomerStats AS (
    SELECT 
        ca.city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca 
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca.city
),
ReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        AVG(sr_return_amt) AS avg_return_amt
    FROM 
        store_returns
    WHERE 
        sr_return_quantity > 0
    GROUP BY 
        sr_item_sk
)
SELECT 
    cs.city,
    ss.total_sales,
    ss.order_count,
    rs.total_returns,
    rs.avg_return_amt,
    CASE 
        WHEN cs.customer_count IS NULL THEN 'No Customers' 
        ELSE 'Customers Active' 
    END AS customer_status
FROM 
    CustomerStats cs
LEFT JOIN 
    SalesSummary ss ON cs.city = (SELECT ca_city FROM customer_address WHERE ca_address_sk = cs.customer_count)
FULL OUTER JOIN 
    ReturnStats rs ON ss.web_site_sk = rs.sr_item_sk
WHERE 
    (ss.total_sales IS NOT NULL OR rs.total_returns IS NOT NULL)
ORDER BY 
    total_sales DESC, city ASC;
