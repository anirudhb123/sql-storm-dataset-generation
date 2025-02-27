
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count
    FROM 
        customer AS c
    JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        cs.total_sales,
        cs.order_count,
        ROW_NUMBER() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_sales > 1000
)
SELECT 
    tc.customer_id,
    tc.total_sales,
    tc.order_count
FROM 
    TopCustomers tc
WHERE 
    tc.sales_rank <= 10;

WITH InventoryStatus AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        SUM(inv.inv_quantity_on_hand) AS total_quantity
    FROM 
        item AS i
    JOIN 
        inventory AS inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
UnderstockedItems AS (
    SELECT 
        is.i_item_id,
        is.total_quantity,
        ROW_NUMBER() OVER (ORDER BY is.total_quantity ASC) AS stock_rank
    FROM 
        InventoryStatus is
    WHERE 
        is.total_quantity < 50
)
SELECT 
    u.i_item_id,
    u.total_quantity
FROM 
    UnderstockedItems u
WHERE 
    u.stock_rank <= 5;

SELECT 
    d.d_year,
    AVG(ws.ws_net_profit) AS average_profit,
    SUM(ws.ws_quantity) AS total_quantity_sold
FROM 
    date_dim AS d
JOIN 
    web_sales AS ws ON d.d_date_sk = ws.ws_sold_date_sk
WHERE 
    d.d_year BETWEEN 2021 AND 2022
GROUP BY 
    d.d_year
ORDER BY 
    d.d_year;
