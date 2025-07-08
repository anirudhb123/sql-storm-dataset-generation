
WITH PopularItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
    UNION ALL
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) + pi.total_quantity AS total_quantity
    FROM 
        web_sales ws
    JOIN 
        PopularItems pi ON ws.ws_item_sk = pi.ws_item_sk
    GROUP BY 
        ws.ws_item_sk
), 
FilteredSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        (ws.ws_sales_price - ws.ws_ext_discount_amt) AS net_sales_price,
        MAX(ws.ws_net_profit) OVER (PARTITION BY ws.ws_item_sk) AS max_profit,
        ws.ws_bill_customer_sk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk IS NOT NULL
        AND ws.ws_sales_price IS NOT NULL
), 
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS return_count,
        SUM(wr_net_loss) AS total_loss
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
    HAVING 
        SUM(wr_net_loss) > 1000
)
SELECT 
    ca.ca_city,
    COUNT(DISTINCT fs.ws_order_number) AS order_count,
    SUM(fs.net_sales_price) AS total_sales,
    AVG(cr.return_count) AS average_returns,
    MAX(cp.cp_catalog_number) AS max_catalog_number
FROM 
    customer_address ca
LEFT JOIN 
    FilteredSales fs ON ca.ca_address_sk = fs.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns cr ON fs.ws_bill_customer_sk = cr.wr_returning_customer_sk
LEFT JOIN 
    catalog_page cp ON fs.ws_item_sk = cp.cp_catalog_page_sk
WHERE 
    ca.ca_city IS NOT NULL
GROUP BY 
    ca.ca_city
ORDER BY 
    total_sales DESC, 
    average_returns ASC
LIMIT 10;
