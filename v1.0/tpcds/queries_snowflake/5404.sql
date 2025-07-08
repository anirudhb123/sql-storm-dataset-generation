
WITH RankedSales AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) AS rnk
    FROM
        web_sales ws
    JOIN
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE
        dd.d_year = 2023
        AND ws.ws_net_paid > 100
),
CustomerDemographics AS (
    SELECT
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_education_status,
        cd.cd_purchase_estimate,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer_demographics cd
    JOIN
        customer c ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_demo_sk, cd.cd_gender, cd.cd_marital_status, cd.cd_education_status, cd.cd_purchase_estimate
),
TopItems AS (
    SELECT
        rs.ws_item_sk,
        SUM(rs.ws_quantity) AS total_quantity_sold,
        SUM(rs.ws_net_paid) AS total_net_paid
    FROM
        RankedSales rs
    WHERE
        rs.rnk <= 5
    GROUP BY
        rs.ws_item_sk
)
SELECT
    ti.ws_item_sk,
    ti.total_quantity_sold,
    ti.total_net_paid,
    cd.cd_gender,
    cd.cd_marital_status,
    cd.cd_education_status,
    cd.customer_count
FROM
    TopItems ti
JOIN
    CustomerDemographics cd ON cd.cd_demo_sk IN (
        SELECT DISTINCT c.c_current_cdemo_sk
        FROM customer c
        JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
        WHERE ws.ws_item_sk = ti.ws_item_sk
    )
ORDER BY
    ti.total_net_paid DESC
FETCH FIRST 10 ROWS ONLY;
