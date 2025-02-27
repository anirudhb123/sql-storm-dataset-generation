
WITH AddressInfo AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_zip
    FROM 
        customer_address
),
WebsiteInfo AS (
    SELECT 
        web_site_id,
        web_name,
        CONCAT(web_street_number, ' ', web_street_name, ' ', web_street_type) AS full_address,
        web_city,
        web_state,
        web_zip
    FROM 
        web_site
),
ReturnAggregate AS (
    SELECT 
        wr_item_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_qty) AS total_quantity_returned,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
SalesSummary AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_ext_sales_price) AS total_sales_amount
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
)
SELECT 
    ai.full_address AS customer_address,
    wi.full_address AS website_address,
    ra.total_returns,
    ra.total_quantity_returned,
    ra.total_return_amount,
    ss.total_sales_quantity,
    ss.total_sales_amount
FROM 
    AddressInfo ai
JOIN 
    WebsiteInfo wi ON ai.ca_city = wi.web_city AND ai.ca_state = wi.web_state 
LEFT JOIN 
    ReturnAggregate ra ON ra.wr_item_sk = ai.ca_address_sk
LEFT JOIN 
    SalesSummary ss ON ss.ws_item_sk = ai.ca_address_sk
WHERE 
    ai.ca_state IN ('CA', 'TX') 
ORDER BY 
    total_sales_amount DESC
LIMIT 50;
