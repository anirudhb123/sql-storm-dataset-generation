
WITH SalesData AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        AVG(ws.ws_net_profit) AS average_net_profit,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_sold
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year BETWEEN 2021 AND 2023
    GROUP BY
        d.d_year, d.d_month_seq
),
CustomerDetails AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sd.total_quantity) AS quantity_by_customer,
        SUM(sd.total_sales) AS sales_by_customer,
        AVG(sd.average_net_profit) AS avg_profit_by_customer
    FROM
        SalesData sd
    JOIN
        customer c ON c.c_customer_sk = sd.total_quantity
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
),
TopCustomers AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cd.sales_by_customer) AS total_sales_by_category
    FROM
        CustomerDetails cd
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
    ORDER BY
        total_sales_by_category DESC
    LIMIT 10
)
SELECT
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_sales_by_category
FROM
    TopCustomers tc
JOIN
    customer c ON c.c_current_cdemo_sk = (
        SELECT cd.cd_demo_sk
        FROM customer_demographics cd
        WHERE cd.cd_gender = tc.cd_gender
        AND cd.cd_marital_status = tc.cd_marital_status
        LIMIT 1
    )
WHERE
    c.c_birth_year BETWEEN 1970 AND 1990
ORDER BY
    total_sales_by_category DESC;
