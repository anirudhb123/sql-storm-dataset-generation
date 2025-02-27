
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year >= 1980 AND c.c_birth_year <= 2000
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c.customer_id,
        c.total_sales,
        c.total_orders,
        c.avg_net_profit,
        DENSE_RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    tu.c_customer_id AS customer_id,
    tu.total_sales AS total_sales,
    tu.total_orders AS total_orders,
    tu.avg_net_profit AS avg_net_profit
FROM 
    TopCustomers tu
WHERE 
    tu.sales_rank <= 10
ORDER BY 
    tu.total_sales DESC;

WITH ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_ext_sales_price) AS total_sales
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
),
TopItems AS (
    SELECT 
        is.item_id,
        is.total_quantity_sold,
        is.total_sales,
        DENSE_RANK() OVER (ORDER BY is.total_sales DESC) AS sales_rank
    FROM 
        ItemSales is
)
SELECT 
    ti.item_id,
    ti.total_quantity_sold,
    ti.total_sales
FROM 
    TopItems ti
WHERE 
    ti.sales_rank <= 10
ORDER BY 
    ti.total_sales DESC;
