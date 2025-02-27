
WITH RankedSales AS (
    SELECT 
        ws_invoice_date_sk,
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2022) 
        AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022)
    GROUP BY 
        ws_invoice_date_sk, ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amt
    FROM 
        web_returns
    WHERE 
        wr_returned_date_sk > (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2021)
    GROUP BY 
        wr_item_sk
),
SalesWithReturns AS (
    SELECT 
        r.ws_item_sk,
        r.total_sales,
        COALESCE(c.total_returns, 0) AS total_returns,
        COALESCE(c.total_return_amt, 0) AS total_return_amt,
        (r.total_sales - COALESCE(c.total_return_amt, 0)) AS net_sales
    FROM 
        RankedSales r
    LEFT JOIN 
        CustomerReturns c ON r.ws_item_sk = c.wr_item_sk
    WHERE 
        r.sales_rank = 1
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    s.net_sales,
    CASE 
        WHEN s.net_sales <= 0 THEN 'No Sales'
        WHEN s.net_sales BETWEEN 1 AND 100 THEN 'Low Sales'
        WHEN s.net_sales BETWEEN 101 AND 500 THEN 'Moderate Sales'
        ELSE 'High Sales'
    END AS sales_category,
    a.ca_city,
    a.ca_state,
    d.d_date AS report_date
FROM 
    SalesWithReturns s
JOIN 
    item i ON s.ws_item_sk = i.i_item_sk
JOIN 
    customer_address a ON a.ca_address_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = (SELECT MIN(ws_bill_customer_sk) FROM web_sales))
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales)
WHERE 
    i.i_current_price > 20.00
ORDER BY 
    net_sales DESC
LIMIT 100;
