
WITH RankedItems AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        RANK() OVER (PARTITION BY i.i_item_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rank
    FROM
        item i
    JOIN
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY
        i.i_item_sk, i.i_item_id, i.i_item_desc
),
MaxSales AS (
    SELECT
        r.i_item_id,
        r.total_quantity_sold
    FROM
        RankedItems r
    WHERE
        r.rank = 1
),
CustomerSales AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_spent
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
TopCustomers AS (
    SELECT
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS customer_rank
    FROM
        CustomerSales cs
)
SELECT
    tc.c_customer_sk,
    tc.c_first_name,
    tc.c_last_name,
    tc.total_spent,
    COALESCE(mi.total_quantity_sold, 0) AS most_sold_quantity,
    COALESCE(mi.total_quantity_sold, 0) / NULLIF(tc.total_spent, 0) AS quantity_to_spending_ratio
FROM
    TopCustomers tc
LEFT JOIN
    MaxSales mi ON tc.c_customer_sk = (
        SELECT
            ws.ws_bill_customer_sk
        FROM
            web_sales ws
        WHERE
            ws.ws_item_sk IN (SELECT i.i_item_sk FROM item i WHERE i.i_item_id = (SELECT i_item_id FROM item LIMIT 1))
        LIMIT 1
    )
WHERE
    tc.customer_rank <= 10
ORDER BY
    tc.total_spent DESC;
