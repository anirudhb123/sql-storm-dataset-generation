
WITH CustomerReturns AS (
    SELECT
        sr_returned_date_sk,
        sr_returning_customer_sk,
        SUM(sr_return_quantity) AS total_return_quantity,
        SUM(sr_return_amt_inc_tax) AS total_return_amount
    FROM
        store_returns
    GROUP BY
        sr_returned_date_sk,
        sr_returning_customer_sk
),
TopCustomers AS (
    SELECT
        cr.sr_returning_customer_sk,
        SUM(cr.total_return_quantity) AS total_quantity,
        SUM(cr.total_return_amount) AS total_amount,
        RANK() OVER (ORDER BY SUM(cr.total_return_quantity) DESC) AS rank
    FROM
        CustomerReturns cr
    GROUP BY
        cr.sr_returning_customer_sk
    HAVING
        SUM(cr.total_return_quantity) > 0
),
ProductSales AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_sales_quantity,
        SUM(ws.ws_net_profit) AS total_profit
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk IN (
            SELECT DISTINCT sr_returned_date_sk FROM store_returns
        )
    GROUP BY
        ws.ws_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    t.total_quantity,
    t.total_amount,
    COALESCE(ps.total_sales_quantity, 0) AS total_product_sales_quantity,
    COALESCE(ps.total_profit, 0) AS total_product_profit
FROM 
    customer c
LEFT JOIN 
    TopCustomers t ON c.c_customer_sk = t.sr_returning_customer_sk
LEFT JOIN 
    ProductSales ps ON ps.ws_item_sk IN (
        SELECT DISTINCT sr_item_sk FROM store_returns sr WHERE sr.sr_returning_customer_sk = t.sr_returning_customer_sk
    )
WHERE 
    c.c_current_addr_sk IS NOT NULL
    AND (t.rank <= 10 OR t.rank IS NULL)
ORDER BY 
    total_amount DESC, 
    c.c_last_name, 
    c.c_first_name;
