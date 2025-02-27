
WITH RankedSales AS (
    SELECT
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity_sold,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank_sales
    FROM
        catalog_sales cs
    JOIN
        date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN
        item i ON cs.cs_item_sk = i.i_item_sk
    WHERE
        dd.d_year = 2023 AND
        i.i_current_price > 50.00
    GROUP BY
        cs.cs_item_sk
),
TopSellingItems AS (
    SELECT
        is_.i_item_id,
        rs.total_quantity_sold,
        rs.total_sales_amount
    FROM
        RankedSales rs
    JOIN
        item is_ ON rs.cs_item_sk = is_.i_item_sk
    WHERE
        rs.rank_sales <= 5
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    ti.i_item_id,
    ti.total_quantity_sold,
    ti.total_sales_amount
FROM
    TopSellingItems ti
JOIN
    web_sales ws ON ti.i_item_id = ws.ws_item_sk
JOIN
    customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
WHERE
    c.c_birth_year BETWEEN 1975 AND 1990
ORDER BY
    ti.total_sales_amount DESC;
