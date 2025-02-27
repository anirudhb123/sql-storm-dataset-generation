
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
ItemSales AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    WHERE 
        ws.ws_sold_date_sk = (SELECT MAX(d_date_sk) FROM date_dim dd WHERE dd.d_date = CURRENT_DATE)
    GROUP BY 
        i.i_item_sk, i.i_item_desc
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS customer_rank
    FROM 
        CustomerSales c
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    ISNULL(i.i_item_desc, 'No Items Sold') AS item_description,
    ISNULL(is.total_quantity_sold, 0) AS quantity_sold
FROM 
    TopCustomers tc
LEFT JOIN 
    ItemSales is ON tc.c_customer_sk = is.total_quantity_sold
WHERE 
    tc.customer_rank <= 10 
    AND (is.total_quantity_sold > 5 OR is.total_quantity_sold IS NULL)
ORDER BY 
    tc.customer_rank, quantity_sold DESC;
