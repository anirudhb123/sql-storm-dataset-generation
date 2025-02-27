
WITH RECURSIVE sales_summary AS (
    SELECT 
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_net_paid) AS total_sales,
        COUNT(ss_ticket_number) AS total_transactions,
        ROW_NUMBER() OVER (PARTITION BY ss_item_sk ORDER BY SUM(ss_net_paid) DESC) AS sales_rank
    FROM 
        store_sales
    GROUP BY 
        ss_item_sk, ss_sold_date_sk
),
ranked_sales AS (
    SELECT 
        item.i_item_id,
        item.i_item_desc,
        COALESCE(sales.total_sales, 0) AS total_sales,
        COALESCE(sales.total_transactions, 0) AS total_transactions,
        RANK() OVER (ORDER BY COALESCE(sales.total_sales, 0) DESC) AS item_rank
    FROM 
        item
    LEFT JOIN 
        (SELECT * FROM sales_summary WHERE sales_rank <= 5) AS sales ON item.i_item_sk = sales.ss_item_sk
)
SELECT 
    customer.c_customer_id,
    customer.c_first_name,
    customer.c_last_name,
    item.i_item_desc,
    sales.total_sales,
    sales.total_transactions
FROM 
    customer
JOIN 
    web_sales ON customer.c_customer_sk = web_sales.ws_bill_customer_sk
JOIN 
    ranked_sales AS sales ON web_sales.ws_item_sk = sales.i_item_sk
WHERE 
    sales.item_rank <= 10
    AND customer.c_birth_year BETWEEN 1980 AND 2000
    AND (customer.c_first_name LIKE 'A%' OR customer.c_last_name LIKE 'B%')
ORDER BY 
    total_sales DESC
FETCH FIRST 100 ROWS ONLY;
