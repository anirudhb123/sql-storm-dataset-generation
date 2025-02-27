
WITH SalesData AS (
    SELECT
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        SUM(ws.ws_ext_sales_price) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_per_item
    FROM
        web_sales ws
    INNER JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE
        cd.cd_gender = 'F' AND
        c.c_birth_month BETWEEN 1 AND 6
    GROUP BY
        ws.ws_item_sk
),
TopSellingItems AS (
    SELECT
        item.i_item_id,
        item.i_product_name,
        sd.total_quantity,
        sd.total_revenue,
        sd.avg_sales_price
    FROM
        SalesData sd
    JOIN
        item ON sd.ws_item_sk = item.i_item_sk
    WHERE
        sd.rank_per_item <= 10
),
AnnualSales AS (
    SELECT
        dd.d_year,
        SUM(td.total_revenue) AS annual_revenue
    FROM
        date_dim dd
    JOIN
        SalesData td ON dd.d_date_sk = CURRENT_DATE - INTERVAL CONCAT(td.rank_per_item, ' day')
    GROUP BY
        dd.d_year
)
SELECT
    ts.i_item_id,
    ts.i_product_name,
    ts.total_quantity,
    ts.total_revenue,
    ts.avg_sales_price,
    COALESCE(as.annual_revenue, 0) AS annual_revenue
FROM
    TopSellingItems ts
LEFT JOIN
    AnnualSales as ON as.d_year = EXTRACT(YEAR FROM CURRENT_DATE)
ORDER BY
    ts.total_revenue DESC;
