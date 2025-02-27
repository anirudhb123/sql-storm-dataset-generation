
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ss.sold_date_sk,
        ss.item_sk,
        ss.ticket_number,
        ss.quantity,
        ss.sales_price,
        ss.ext_sales_price,
        ss.ext_tax,
        CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
        d.d_date AS sale_date,
        ROW_NUMBER() OVER (PARTITION BY ss.item_sk ORDER BY ss.sold_date_sk DESC) AS rn
    FROM 
        store_sales ss
    JOIN 
        customer c ON ss.customer_sk = c.c_customer_sk
    JOIN 
        date_dim d ON ss.sold_date_sk = d.d_date_sk
    WHERE
        ss.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim) - 365
),
CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.returning_customer_sk,
        SUM(sr.return_quantity) AS total_returned_quantity,
        SUM(sr.return_amt) AS total_returned_amt
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk, sr.returning_customer_sk
),
AggregatedSales AS (
    SELECT 
        item_sk,
        SUM(quantity) AS total_quantity_sold,
        SUM(ext_sales_price) AS total_sales_value,
        AVG(ext_tax) AS avg_tax
    FROM 
        SalesCTE
    GROUP BY 
        item_sk
)
SELECT 
    a.item_sk AS "Item SK",
    a.total_quantity_sold AS "Total Sold",
    a.total_sales_value AS "Total Sales Value",
    a.avg_tax AS "Average Tax",
    COALESCE(r.total_returned_quantity, 0) AS "Total Returned Quantity",
    COALESCE(r.total_returned_amt, 0) AS "Total Returned Amount",
    (a.total_sales_value - COALESCE(r.total_returned_amt, 0)) AS "Net Sales Value",
    (a.total_quantity_sold - COALESCE(r.total_returned_quantity, 0)) AS "Net Sold Quantity"
FROM 
    AggregatedSales a
LEFT JOIN 
    CustomerReturns r ON a.item_sk = r.returning_customer_sk
WHERE 
    a.total_quantity_sold > 0
ORDER BY 
    "Net Sales Value" DESC
LIMIT 100;
