
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk, 
        ws.order_number,
        ws.sales_price,
        ws.ext_discount_amt,
        ws.ext_sales_price,
        ws.ext_tax,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.order_number DESC) AS rn
    FROM 
        web_sales ws
    WHERE 
        ws.ship_date_sk IS NOT NULL
        AND ws.sales_price IS NOT NULL
        AND ws.ext_sales_price - ws.ext_discount_amt > 0
),
CustomerReturnStats AS(
    SELECT 
        c.c_customer_sk,
        COUNT(sr.ticket_number) AS total_returns,
        SUM(sr.return_amt_inc_tax) AS total_return_amt
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.customer_sk
    GROUP BY 
        c.c_customer_sk
),
WebCatalogSales AS (
    SELECT 
        cs.item_sk,
        SUM(cs.quantity) AS catalog_quantity,
        SUM(cs.net_profit) AS total_net_profit,
        MAX(cs.sales_price) AS max_sales_price
    FROM 
        catalog_sales cs
    GROUP BY 
        cs.item_sk
)
SELECT 
    ca.city AS customer_city,
    SUM(rk.sales_price) AS total_sales,
    AVG(rk.ext_sales_price) AS avg_sales_price,
    COALESCE(SUM(cr.total_returns), 0) AS total_returned,
    SUM(cust_sales.catalog_quantity) AS total_catalog_quantity,
    MAX(cust_sales.max_sales_price) AS highest_catalog_price,
    CASE 
        WHEN SUM(ws.ext_sales_price) IS NULL THEN 'No Sales Data'
        ELSE 'Sales Data Available'
    END AS sales_data_status
FROM 
    RankedSales rk
FULL OUTER JOIN 
    CustomerReturnStats cr ON rk.web_site_sk = cr.c_customer_sk
LEFT JOIN 
    WebCatalogSales cust_sales ON rk.order_number = cust_sales.item_sk
JOIN 
    customer_address ca ON ca.ca_address_sk = cr.c_customer_sk
WHERE 
    ca.state IN ('CA', 'NY', 'TX')
    AND (rk.sales_price >= 10 OR rk.total_sales > 100)
GROUP BY 
    ca.city
HAVING 
    SUM(rk.sales_price) > 1000 OR COUNT(DISTINCT cr.c_customer_sk) > 10
ORDER BY 
    total_sales DESC;
