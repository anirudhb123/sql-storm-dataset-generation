
WITH CustomerReturns AS (
    SELECT 
        c.c_customer_id,
        COUNT(DISTINCT sr_item_sk) AS total_returned_items,
        SUM(sr_return_amt_inc_tax) AS total_returned_value
    FROM 
        customer c
    LEFT JOIN 
        store_returns sr ON c.c_customer_sk = sr.sr_customer_sk
    GROUP BY 
        c.c_customer_id
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_sales_price) AS total_sales_value,
        COUNT(ws.ws_order_number) AS total_sales_count
    FROM 
        item i
    LEFT JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id, i.i_product_name
),
TopCustomers AS (
    SELECT 
        cr.c_customer_id,
        cr.total_returned_items,
        cr.total_returned_value,
        RANK() OVER (ORDER BY cr.total_returned_value DESC) AS rank
    FROM 
        CustomerReturns cr
)
SELECT 
    tc.c_customer_id,
    COALESCE(tc.total_returned_items, 0) AS total_returned_items,
    COALESCE(tc.total_returned_value, 0) AS total_returned_value,
    CASE 
        WHEN tc.total_returned_value > 1000 THEN 'High Return'
        WHEN tc.total_returned_value BETWEEN 500 AND 1000 THEN 'Medium Return'
        ELSE 'Low Return'
    END AS return_category,
    isales.i_item_id,
    isales.i_product_name,
    isales.total_sales_value,
    isales.total_sales_count
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    ItemSales isales ON tc.c_customer_id = (
        SELECT c.c_customer_id 
        FROM customer c 
        WHERE c.c_customer_sk = (
            SELECT sr.sr_customer_sk 
            FROM store_returns sr 
            WHERE sr.sr_item_sk = isales.i_item_sk 
            LIMIT 1
        )
    )
WHERE 
    tc.rank <= 10 OR tc.c_customer_id IS NULL
ORDER BY 
    tc.rank, isales.i_product_name;
