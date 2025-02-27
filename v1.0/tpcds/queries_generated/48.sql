
WITH CustomerReturns AS (
    SELECT
        cr.returning_customer_sk,
        cr.return_quantity,
        cr.return_amount,
        cr.return_tax,
        cr.refunded_cash,
        cr.refunded_customer_sk,
        DATEADD(DAY, -1, d.d_date) AS return_date,
        DENSE_RANK() OVER (PARTITION BY cr.returning_customer_sk ORDER BY cr.returned_date_sk DESC) AS return_rank
    FROM
        catalog_returns cr
    JOIN
        date_dim d ON cr.returned_date_sk = d.d_date_sk
    WHERE
        cr.return_quantity > 0
),
TopCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(COALESCE(cr.return_quantity, 0)) AS total_returned_quantity,
        SUM(COALESCE(cr.return_amount, 0)) AS total_returned_amount,
        COUNT(DISTINCT cr.returning_customer_sk) AS return_count
    FROM
        customer c
    LEFT JOIN
        CustomerReturns cr ON c.c_customer_sk = cr.returning_customer_sk
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING
        SUM(COALESCE(cr.return_quantity, 0)) > 10
),
SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_sales_price) AS total_sales
    FROM
        web_sales ws
    GROUP BY
        ws.ws_item_sk
),
InventoryData AS (
    SELECT
        inv.inv_item_sk,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        inventory inv
    GROUP BY
        inv.inv_item_sk
)

SELECT
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    COALESCE(SUM(CASE WHEN ct.return_rank = 1 THEN ct.return_quantity END), 0) AS last_return_quantity,
    COALESCE(SUM(ct.total_returned_amount), 0) AS total_returned_amount,
    COALESCE(sd.total_quantity_sold, 0) AS total_quantity_sold,
    COALESCE(id.total_inventory, 0) AS total_inventory,
    CASE
        WHEN COALESCE(sd.total_sales, 0) > 0 THEN (COALESCE(ct.total_returned_amount, 0) / sd.total_sales) * 100
        ELSE 0
    END AS return_rate_percentage
FROM
    TopCustomers ct
JOIN
    customer c ON ct.c_customer_sk = c.c_customer_sk
LEFT JOIN
    SalesData sd ON sd.ws_item_sk = ct.c_customer_sk  -- Assuming customer items are mapped, otherwise adjust the join
LEFT JOIN
    InventoryData id ON id.inv_item_sk = ct.c_customer_sk  -- Assuming customer items are mapped, otherwise adjust the join
GROUP BY
    c.c_customer_sk, c.c_first_name, c.c_last_name
ORDER BY
    return_rate_percentage DESC;
