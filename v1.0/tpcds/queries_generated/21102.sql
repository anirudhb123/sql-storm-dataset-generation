
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
), 
CustomerReturns AS (
    SELECT 
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_returns,
        COUNT(DISTINCT sr_ticket_number) AS num_returns
    FROM 
        store_returns 
    WHERE 
        sr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        sr_returning_customer_sk
), 
FilteredCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_marital_status,
        cd.cd_gender
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' 
        AND cd.cd_gender = 'F'
), 
AggregatedSales AS (
    SELECT 
        item.i_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        item ON ws.ws_item_sk = item.i_item_sk
    GROUP BY 
        item.i_item_sk
)
SELECT 
    fc.c_customer_sk,
    fc.c_first_name,
    fc.c_last_name,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(a.total_sales, 0) AS total_sales,
    RANK() OVER (ORDER BY COALESCE(a.total_sales, 0) DESC) AS sales_rank
FROM 
    FilteredCustomers fc
LEFT JOIN 
    CustomerReturns cr ON fc.c_customer_sk = cr.sr_returning_customer_sk
LEFT JOIN 
    AggregatedSales a ON a.i_item_sk IN (SELECT DISTINCT ws_item_sk FROM web_sales WHERE ws_web_page_sk IN (SELECT wp_web_page_sk FROM web_page WHERE wp_url LIKE '%discount%'))
WHERE 
    COALESCE(cr.total_returns, 0) < 5
    AND (fc.c_customer_sk IN (SELECT DISTINCT ws_bill_customer_sk FROM web_sales WHERE ws_sales_price > 100) OR fc.c_customer_sk IS NULL)
ORDER BY 
    sales_rank, fc.c_last_name ASC;
