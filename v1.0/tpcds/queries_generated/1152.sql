
WITH RankedSales AS (
    SELECT 
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk, 
        SUM(wr_return_amt) AS total_returned_amt,
        COUNT(*) AS total_returns
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
SalesAndReturns AS (
    SELECT 
        r.rcustomer_sk,
        SUM(s.ws_sales_price * s.ws_quantity) AS total_sales,
        COALESCE(cr.total_returned_amt, 0) AS total_returned_amt,
        SUM(s.ws_sales_price * s.ws_quantity) - COALESCE(cr.total_returned_amt, 0) AS net_sales
    FROM 
        (SELECT DISTINCT ws_ship_customer_sk AS rcustomer_sk FROM web_sales) r
    LEFT JOIN 
        web_sales s ON r.rcustomer_sk = s.ws_ship_customer_sk
    LEFT JOIN 
        CustomerReturns cr ON r.rcustomer_sk = cr.wr_returning_customer_sk
    GROUP BY 
        r.rcustomer_sk
),
TopSellingItems AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales
    FROM 
        RankedSales rs
    WHERE 
        rs.SalesRank <= 5
    GROUP BY 
        rs.ws_item_sk
)
SELECT 
    c.c_customer_id,
    COALESCE(sar.total_sales, 0) AS total_sales,
    COALESCE(sar.total_returned_amt, 0) AS total_returned_amt,
    COALESCE(sar.net_sales, 0) AS net_sales,
    tsi.total_sales AS top_item_sales
FROM 
    customer c
LEFT JOIN 
    SalesAndReturns sar ON c.c_customer_sk = sar.rcustomer_sk
LEFT JOIN 
    TopSellingItems tsi ON tsi.ws_item_sk = (SELECT MIN(rs.ws_item_sk) FROM RankedSales rs WHERE rs.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023))
WHERE 
    c.c_birth_year IS NOT NULL
ORDER BY 
    c.c_customer_id;
