
WITH CustomerReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(DISTINCT wr_order_number) AS total_returns,
        SUM(wr_return_amt) AS total_return_amount
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
),
ItemSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(ws_net_paid) AS total_sales
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
HighValueItems AS (
    SELECT 
        i_item_sk,
        i_item_desc,
        i_current_price
    FROM 
        item 
    WHERE 
        i_current_price > (SELECT AVG(i_current_price) FROM item)
),
ReturnStats AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cr.total_returns,
        cr.total_return_amount,
        COALESCE(hi.total_quantity_sold, 0) AS total_quantity_sold,
        COALESCE(hi.total_sales, 0) AS total_sales
    FROM 
        customer c
    LEFT JOIN 
        CustomerReturns cr ON c.c_customer_sk = cr.wr_returning_customer_sk
    LEFT JOIN 
        ItemSales hi ON hi.ws_item_sk IN (
            SELECT 
                sr_item_sk 
            FROM 
                store_returns 
            WHERE 
                sr_customer_sk = c.c_customer_sk
        )
)
SELECT 
    r.c_customer_id,
    r.c_first_name,
    r.c_last_name,
    COALESCE(r.total_returns, 0) AS total_returns,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    CASE 
        WHEN r.total_return_amount > 1000 THEN 'High Return Value'
        ELSE 'Normal Return Value'
    END AS return_value_category,
    ROW_NUMBER() OVER (PARTITION BY r.total_return_amount ORDER BY r.total_quantity_sold DESC) AS ranking,
    CONCAT(r.c_first_name, ' ', r.c_last_name) AS full_name
FROM 
    ReturnStats r
WHERE 
    r.total_sales > 500
ORDER BY 
    return_value_category, total_returns DESC;
