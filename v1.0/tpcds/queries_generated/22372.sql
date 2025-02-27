
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS Rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
),
AggregatedReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS TotalReturnQty,
        SUM(wr.wr_return_amt) AS TotalReturnAmt
    FROM 
        web_returns wr
    GROUP BY 
        wr.wr_item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT cs.cs_order_number) AS TotalCatalogSales,
        COUNT(DISTINCT ss.ss_ticket_number) AS TotalStoreSales
    FROM 
        customer c
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN 
        store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        c.c_current_cdemo_sk IS NOT NULL 
        AND (c.c_birth_date IS NOT NULL OR c.c_birth_month IS NOT NULL)
    GROUP BY 
        c.c_customer_sk
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    COUNT(DISTINCT cs.c_customer_sk) AS UniqueCustomers,
    COALESCE(SUM(rs.ws_sales_price), 0) AS TotalSalesPrice,
    COALESCE(SUM(ar.TotalReturnQty), 0) AS TotalReturnedQuantity,
    COALESCE(SUM(ar.TotalReturnAmt), 0) AS TotalReturnedAmount,
    AVG(CASE WHEN cs.TotalCatalogSales > 0 THEN cs.TotalCatalogSales ELSE NULL END) AS AvgCatalogSales,
    MAX(CASE WHEN ca.ca_state IN ('NY', 'CA') THEN cs.TotalStoreSales ELSE 0 END) AS MaxStoreSalesInSpecificStates
FROM 
    customer_address ca
LEFT JOIN 
    CustomerStats cs ON cs.c_customer_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales rs ON rs.ws_item_sk = cs.c_customer_sk
LEFT JOIN 
    AggregatedReturns ar ON ar.wr_item_sk = rs.ws_item_sk
WHERE 
    (ca.ca_city IS NOT NULL OR ca.ca_county IS NULL)
    AND (ca.ca_country = 'USA' OR ca.ca_state IS NULL)
GROUP BY 
    ca.ca_address_id, ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT cs.c_customer_sk) > 10
ORDER BY 
    TotalSalesPrice DESC,
    UniqueCustomers ASC;
