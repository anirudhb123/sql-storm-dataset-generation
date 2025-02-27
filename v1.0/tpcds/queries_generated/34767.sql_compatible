
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk, 
        SUM(ws_quantity) AS total_quantity, 
        SUM(ws_sales_price) AS total_sales, 
        ROW_NUMBER() OVER (ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
),
TopItems AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        s.total_quantity,
        s.total_sales
    FROM item i
    JOIN SalesCTE s ON i.i_item_sk = s.ws_item_sk
    WHERE s.sales_rank <= 10
),
CustomerReturnStats AS (
    SELECT 
        c.c_customer_id, 
        COUNT(DISTINCT wr_return_number) AS return_count,
        SUM(wr_return_amt_inc_tax) AS total_returned
    FROM customer c
    LEFT JOIN web_returns wr ON c.c_customer_sk = wr.w_returning_customer_sk
    GROUP BY c.c_customer_id
),
SalesDistribution AS (
    SELECT 
        d.d_year,
        d.d_month_seq,
        SUM(ws_net_paid_inc_tax) AS monthly_sales,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year >= 2022
    GROUP BY d.d_year, d.d_month_seq
),
CombinedStats AS (
    SELECT 
        ti.i_item_id,
        ti.i_item_desc,
        cr.c_customer_id,
        cr.return_count,
        cr.total_returned,
        sd.monthly_sales
    FROM TopItems ti
    JOIN CustomerReturnStats cr ON cr.c_customer_id IS NOT NULL
    LEFT JOIN SalesDistribution sd ON sd.monthly_sales IS NOT NULL
)
SELECT 
    c.c_customer_id,
    COUNT(DISTINCT s.ws_order_number) AS total_sales,
    SUM(s.ws_net_paid) AS gross_sales,
    SUM(COALESCE(r.wr_return_amt, 0)) AS total_returns,
    COUNT(DISTINCT r.wr_order_number) AS total_returned_orders
FROM customer c
LEFT JOIN web_sales s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN web_returns r ON c.c_customer_sk = r.w_returning_customer_sk
WHERE c.c_first_shipto_date_sk IS NOT NULL
GROUP BY c.c_customer_id
HAVING SUM(s.ws_net_paid) > 1000 AND COUNT(DISTINCT s.ws_order_number) > 5
ORDER BY gross_sales DESC;
