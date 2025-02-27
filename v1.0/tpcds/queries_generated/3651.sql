
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_quantity,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_quantity DESC) AS rank_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS rank_price
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN (SELECT d_date_sk FROM date_dim WHERE d_date = '2021-01-01') AND (SELECT d_date_sk FROM date_dim WHERE d_date = '2021-12-31')
),
TopSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity,
        SUM(rs.ws_sales_price) AS total_sales_price
    FROM 
        RankedSales rs
    WHERE 
        rs.rank_quantity <= 5 OR rs.rank_price <= 5
    GROUP BY 
        rs.ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_return_quantity,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    ca.ca_city,
    SUM(ts.total_quantity) AS total_sold_quantity,
    SUM(ts.total_sales_price) AS total_sold_price,
    COALESCE(SUM(cr.total_return_quantity), 0) AS total_return_quantity,
    COALESCE(SUM(cr.total_return_amount), 0) AS total_return_amount,
    SUM(ts.total_sales_price) - COALESCE(SUM(cr.total_return_amount), 0) AS net_sales
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
LEFT JOIN 
    TopSales ts ON c.c_customer_sk = ts.ws_item_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
WHERE 
    ca.ca_state IN ('CA', 'TX') AND
    (c.c_birth_year > 1980 OR c.c_city IS NOT NULL)
GROUP BY 
    ca.ca_city
ORDER BY 
    net_sales DESC
LIMIT 10;
