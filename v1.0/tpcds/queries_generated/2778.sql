
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_city ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, c.c_city
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_sales,
        cs.order_count
    FROM 
        CustomerSales cs
    WHERE 
        cs.sales_rank <= 10
),
StoreReturns AS (
    SELECT 
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_returns,
        SUM(sr.sr_return_amt) AS total_return_amount,
        sm.sm_type
    FROM 
        store_returns sr
    JOIN 
        ship_mode sm ON sr.sr_ship_mode_sk = sm.sm_ship_mode_sk
    GROUP BY 
        sr.sr_item_sk, sm.sm_type
),
SellableItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        COALESCE(SUM(ws.ws_quantity), 0) AS total_sold,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returned
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    LEFT JOIN 
        store_returns sr ON i.i_item_sk = sr.sr_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_product_name
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    si.i_product_name,
    si.total_sold,
    si.total_returned,
    COALESCE(sr.total_returns, 0) AS total_returns,
    COALESCE(sr.total_return_amount, 0) AS total_return_amount
FROM 
    TopCustomers tc
JOIN 
    SellableItems si ON si.total_sold > 0
LEFT JOIN 
    StoreReturns sr ON si.i_item_sk = sr.sr_item_sk
WHERE 
    si.total_returned < si.total_sold
ORDER BY 
    tc.total_sales DESC, si.total_sold DESC;
