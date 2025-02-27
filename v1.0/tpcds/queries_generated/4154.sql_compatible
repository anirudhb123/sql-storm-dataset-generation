
WITH RankedSales AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sales_price IS NOT NULL
),
TotalReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returned
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
CustomerAddress AS (
    SELECT 
        ca_address_sk,
        CONCAT(ca_street_number, ' ', ca_street_name, ' ', ca_street_type) AS full_address,
        ca_city,
        ca_state,
        ca_country
    FROM 
        customer_address
    WHERE 
        ca_city IS NOT NULL AND ca_state IS NOT NULL
),
TopSellingItems AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        SUM(ws_quantity) > 100
)
SELECT 
    tsi.ws_item_sk,
    MAX(rs.ws_sales_price) AS max_sales_price,
    COALESCE(tr.total_returned, 0) AS total_returned,
    ca.full_address,
    ca.ca_city,
    ca.ca_state,
    ca.ca_country
FROM 
    TopSellingItems tsi
LEFT JOIN 
    RankedSales rs ON tsi.ws_item_sk = rs.ws_item_sk AND rs.sales_rank = 1
LEFT JOIN 
    TotalReturns tr ON tsi.ws_item_sk = tr.wr_item_sk
INNER JOIN 
    customer AS c ON c.c_current_addr_sk = ca.ca_address_sk
INNER JOIN 
    CustomerAddress ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    c.c_first_name LIKE 'A%' AND 
    (c.c_birth_year BETWEEN 1980 AND 1990 OR c.c_current_hdemo_sk IS NOT NULL)
GROUP BY 
    tsi.ws_item_sk, ca.full_address, ca.ca_city, ca.ca_state, ca.ca_country
ORDER BY 
    max_sales_price DESC
LIMIT 100;
