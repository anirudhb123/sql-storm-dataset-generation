
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sold_date_sk DESC) AS rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN 20230101 AND 20231231
),
CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_quantity) AS total_returned
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
AddressDetails AS (
    SELECT 
        ca.ca_address_sk,
        CONCAT(ca.ca_street_number, ' ', ca.ca_street_name, ' ', ca.ca_street_type) AS full_address
    FROM 
        customer_address ca
    WHERE 
        ca.ca_state IN ('CA', 'NY', 'TX')
),
TotalSales AS (
    SELECT 
        item.i_item_id,
        SUM(ws.ws_sales_price) AS total_sales
    FROM 
        item
    JOIN 
        web_sales ws ON item.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        item.i_item_id
),
DiverseResults AS (
    SELECT 
        a.full_address,
        cs.total_sales,
        COALESCE(cr.total_returned, 0) AS total_returns,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        AddressDetails a
    JOIN 
        TotalSales cs ON cs.i_item_id = a.ca_address_sk -- ambiguous join for performance testing
    LEFT JOIN 
        CustomerReturns cr ON cr.returning_customer_sk = a.ca_address_sk
)
SELECT 
    d.full_address,
    d.total_sales,
    d.total_returns,
    CASE 
        WHEN d.sales_rank <= 10 THEN 'Top Selling'
        WHEN d.total_returns > 0 THEN 'Check Returns'
        ELSE 'Regular'
    END AS category
FROM 
    DiverseResults d
WHERE 
    d.total_sales > (SELECT AVG(total_sales) FROM TotalSales)
UNION ALL
SELECT 
    'Summary' AS full_address,
    SUM(total_sales) AS total_sales,
    SUM(total_returns) AS total_returns,
    'Aggregate' AS category
FROM 
    DiverseResults
GROUP BY 
    '1'; 
