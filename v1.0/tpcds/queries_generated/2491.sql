
WITH RecentWebSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        ws.total_quantity,
        ws.total_sales
    FROM 
        item i
    JOIN 
        RecentWebSales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.rn = 1
),
CustomerReturns AS (
    SELECT 
        wr_refunded_customer_sk,
        SUM(wr_return_quantity) AS total_returned_quantity,
        SUM(wr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        web_returns
    GROUP BY 
        wr_refunded_customer_sk
),
StoreReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
AllReturns AS (
    SELECT 
        coalesce(wr.wr_refunded_customer_sk, sr.sr_customer_sk) AS customer_sk,
        COALESCE(wr.total_returned_quantity, 0) + COALESCE(sr.total_returned_quantity, 0) AS total_returned_quantity,
        COALESCE(wr.total_returned_amount, 0) + COALESCE(sr.total_returned_amount, 0) AS total_returned_amount
    FROM 
        CustomerReturns wr
    FULL OUTER JOIN 
        StoreReturns sr ON wr.wr_refunded_customer_sk = sr.sr_customer_sk
)
SELECT 
    ci.c_customer_id,
    ci.c_first_name,
    ci.c_last_name,
    ti.i_product_name,
    ti.total_quantity,
    ti.total_sales,
    ar.total_returned_quantity,
    ar.total_returned_amount
FROM 
    customer ci
JOIN 
    TopItems ti ON ci.c_customer_sk = ti.i_item_sk
LEFT JOIN 
    AllReturns ar ON ci.c_customer_sk = ar.customer_sk
WHERE 
    (ar.total_returned_quantity > 0 OR ar.total_returned_amount IS NOT NULL)
ORDER BY 
    ti.total_sales DESC, ci.c_last_name;
