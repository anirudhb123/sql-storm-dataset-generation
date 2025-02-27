
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_transactions,
        COUNT(DISTINCT ss.ss_item_sk) AS unique_items_purchased
    FROM 
        customer AS c
    JOIN 
        store_sales AS ss ON c.c_customer_sk = ss.ss_customer_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM 
        CustomerSales AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
),
ItemSummary AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ss.ss_quantity) AS total_sold,
        SUM(ss.ss_sales_price) AS total_revenue
    FROM 
        item AS i
    JOIN 
        store_sales AS ss ON i.i_item_sk = ss.ss_item_sk
    WHERE 
        ss.ss_sold_date_sk BETWEEN 2400 AND 2450
    GROUP BY 
        i.i_item_sk, i.i_item_id, i.i_item_desc
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    tc.total_transactions,
    tc.unique_items_purchased,
    is.i_item_id,
    is.i_item_desc,
    is.total_sold,
    is.total_revenue
FROM 
    TopCustomers AS tc
JOIN 
    ItemSummary AS is ON tc.customer_rank <= 10
ORDER BY 
    tc.customer_rank, is.total_revenue DESC;
