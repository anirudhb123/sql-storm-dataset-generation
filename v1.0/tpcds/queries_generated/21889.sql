
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales
), 
TopSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales
    FROM 
        RankedSales
    WHERE 
        price_rank <= 5
    GROUP BY 
        ws_item_sk
),
CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_quantity) AS total_returned_items
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
    HAVING 
        SUM(wr_return_quantity) > 0
),
SalesReturns AS (
    SELECT
        sr_customer_sk,
        COUNT(sr_item_sk) AS return_count,
        SUM(sr_return_amt_inc_tax) AS total_return_value
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        COUNT(sr_item_sk) > 5
)
SELECT 
    c.c_customer_id,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    SUM(ws_sales_price) AS total_spent,
    COALESCE(r.total_returned_items, 0) AS total_returns,
    COALESCE(s.return_count, 0) AS store_return_count,
    GREATEST(
        SUM(ws_sales_price) - COALESCE(s.total_return_value, 0),
        0
    ) AS net_spent
FROM 
    customer c
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.wr_returning_customer_sk
LEFT JOIN 
    SalesReturns s ON c.c_customer_sk = s.sr_customer_sk
WHERE 
    c.c_birth_year < 1990
    AND COALESCE(c.c_preferred_cust_flag, 'N') = 'Y'
    AND EXISTS (
        SELECT 1 
        FROM TopSales ts 
        WHERE ts.ws_item_sk = ws.ws_item_sk
    )
GROUP BY 
    c.c_customer_id, ca.ca_city
HAVING 
    net_spent > 1000
ORDER BY 
    total_spent DESC
LIMIT 20;
