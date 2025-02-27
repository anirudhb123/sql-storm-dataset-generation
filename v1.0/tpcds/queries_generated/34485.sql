
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),

TopSales AS (
    SELECT 
        ws_item_sk,
        total_quantity,
        total_sales
    FROM 
        SalesCTE
    WHERE 
        rn <= 10
),

CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),

FinalResults AS (
    SELECT 
        cu.c_customer_id,
        ca.ca_city,
        COALESCE(rs.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(rs.total_returned_amount, 0) AS total_returned_amount,
        ts.total_quantity,
        ts.total_sales
    FROM 
        customer AS cu
    LEFT JOIN 
        customer_address AS ca ON cu.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        TopSales AS ts ON cu.c_customer_sk = ts.ws_item_sk
    LEFT JOIN 
        CustomerReturns AS rs ON cu.c_customer_sk = rs.wr_returning_customer_sk
)

SELECT 
    f.c_customer_id,
    f.ca_city,
    SUM(f.total_returned_quantity) AS total_returned_quantity,
    SUM(f.total_returned_amount) AS total_returned_amount,
    SUM(f.total_sales) AS total_sales_amount,
    AVG(f.total_sales) OVER() AS average_sales_per_customer,
    COUNT(f.total_returned_quantity) FILTER (WHERE f.total_returned_quantity > 0) AS number_of_customers_with_returns
FROM 
    FinalResults AS f
GROUP BY 
    f.c_customer_id, f.ca_city
ORDER BY 
    total_sales_amount DESC, total_returned_amount ASC
LIMIT 100;
