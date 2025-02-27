
WITH CustomerTransactions AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerTransactions
)
SELECT 
    tc.c_customer_id,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_quantity,
    tc.total_spent,
    tc.total_orders
FROM 
    TopCustomers tc
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_spent DESC;

WITH ItemSales AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
),
TopItems AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY total_net_profit DESC) AS rank
    FROM 
        ItemSales
)
SELECT 
    ti.i_item_id,
    ti.i_item_desc,
    ti.total_quantity_sold,
    ti.total_net_profit
FROM 
    TopItems ti
WHERE 
    ti.rank <= 10
ORDER BY 
    ti.total_net_profit DESC;

SELECT 
    d.d_year,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
    SUM(ss.ss_net_paid_inc_tax) AS total_revenue,
    AVG(ss.ss_net_profit) AS avg_net_profit
FROM 
    store_sales ss
JOIN 
    date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2023
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;

SELECT 
    cc.cc_call_center_id,
    COUNT(DISTINCT cr.cr_order_number) AS total_catalog_returns,
    SUM(cr.cr_return_amount) AS total_returned_amount
FROM 
    catalog_returns cr
JOIN 
    call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
GROUP BY 
    cc.cc_call_center_id
ORDER BY 
    total_catalog_returns DESC;
