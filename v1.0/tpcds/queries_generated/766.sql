
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        RANK() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM 
        customer AS c
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
HighValueCustomers AS (
    SELECT 
        c.customer_sk,
        c.total_sales,
        c.order_count
    FROM 
        CustomerSales AS c
    WHERE 
        c.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
),
ProductSales AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        SUM(ws.ws_quantity) AS quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        item AS i
    JOIN 
        web_sales AS ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_sk, i.i_item_id
),
TopProducts AS (
    SELECT 
        p.i_item_id,
        p.quantity_sold,
        p.total_net_profit
    FROM 
        ProductSales AS p
    WHERE 
        p.profit_rank <= 10
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    c.total_sales,
    p.i_item_id,
    p.quantity_sold,
    p.total_net_profit
FROM 
    HighValueCustomers AS c
JOIN 
    TopProducts AS p ON c.customer_sk = p.i_item_id
WHERE 
    c.order_count > 5
ORDER BY 
    c.total_sales DESC, p.total_net_profit DESC;
