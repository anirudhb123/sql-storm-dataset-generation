
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_income,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        cs.c_customer_id,
        cs.total_quantity,
        cs.total_income,
        cs.order_count,
        RANK() OVER (ORDER BY cs.total_income DESC) AS income_rank
    FROM 
        CustomerSales cs
),
TopItemReturns AS (
    SELECT 
        wr.wr_item_sk,
        SUM(wr.wr_return_quantity) AS total_returned
    FROM 
        web_returns wr
    WHERE 
        wr.wr_returned_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2023)
    GROUP BY 
        wr.wr_item_sk
),
ReturnDetails AS (
    SELECT 
        ti.wr_item_sk,
        ti.total_returned,
        i.i_item_desc,
        i.i_current_price,
        (i.i_current_price * ti.total_returned) AS total_value_of_returns
    FROM 
        TopItemReturns ti
    JOIN 
        item i ON ti.wr_item_sk = i.i_item_sk
)
SELECT 
    tc.c_customer_id,
    tc.total_quantity,
    tc.total_income,
    tc.order_count,
    COALESCE(rt.total_value_of_returns, 0) AS total_value_of_returns
FROM 
    TopCustomers tc
LEFT JOIN 
    ReturnDetails rt ON tc.c_customer_id = (
        SELECT 
            wr.wr_returning_customer_sk 
        FROM 
            web_returns wr 
        WHERE 
            wr.wr_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_current_price > 100)
        LIMIT 1
    )
ORDER BY 
    tc.income_rank
LIMIT 100;
