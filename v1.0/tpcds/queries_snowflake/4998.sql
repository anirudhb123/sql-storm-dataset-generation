
WITH CustomerSales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders,
        MAX(d.d_date) AS last_purchase_date
    FROM
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_id
),
TopCustomers AS (
    SELECT
        c.c_customer_id AS customer_id,
        c.total_sales,
        RANK() OVER (ORDER BY c.total_sales DESC) AS sales_rank
    FROM
        CustomerSales c
)
SELECT
    tc.customer_id,
    tc.total_sales,
    tc.sales_rank,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    CASE 
        WHEN tc.sales_rank <= 10 THEN 'Top Customer'
        ELSE 'Regular Customer'
    END AS customer_type,
    LISTAGG(DISTINCT CONCAT(i.i_product_name, ' (', ws.ws_quantity, ')'), '; ') AS purchased_items
FROM
    TopCustomers tc
LEFT JOIN customer c ON c.c_customer_id = tc.customer_id
LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
LEFT JOIN item i ON ws.ws_item_sk = i.i_item_sk
WHERE
    (ca.ca_state IS NULL OR ca.ca_state NOT IN ('CA', 'NY')) 
    AND tc.total_sales > (SELECT AVG(total_sales) FROM CustomerSales)
GROUP BY
    tc.customer_id, 
    tc.total_sales, 
    tc.sales_rank, 
    ca.ca_city
HAVING
    COUNT(ws.ws_net_paid_inc_tax) IS NOT NULL
ORDER BY
    tc.sales_rank;
