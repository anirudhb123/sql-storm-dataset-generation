
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS rank
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023
    GROUP BY ws.ws_item_sk
),
TopItems AS (
    SELECT
        ri.ws_item_sk,
        ri.total_quantity,
        ri.total_sales,
        i.i_item_desc,
        i.i_current_price,
        i.i_brand,
        i.category
    FROM RankedSales ri
    JOIN item i ON ri.ws_item_sk = i.i_item_sk
    WHERE ri.rank <= 10
),
ItemDemographics AS (
    SELECT 
        ti.ws_item_sk,
        COUNT(DISTINCT c.c_customer_sk) AS unique_customers,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        MAX(cd.cd_credit_rating) AS highest_credit_rating
    FROM TopItems ti
    LEFT JOIN web_sales ws ON ti.ws_item_sk = ws.ws_item_sk
    LEFT JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY ti.ws_item_sk
)
SELECT
    ti.i_item_desc,
    ti.total_quantity,
    ti.total_sales,
    id.unique_customers,
    id.avg_purchase_estimate,
    id.highest_credit_rating
FROM TopItems ti
JOIN ItemDemographics id ON ti.ws_item_sk = id.ws_item_sk
ORDER BY ti.total_sales DESC;
