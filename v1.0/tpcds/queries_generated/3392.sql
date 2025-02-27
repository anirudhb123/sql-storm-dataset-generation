
WITH SalesData AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_item_sk,
        SUM(ws.ws_sales_price * ws.ws_quantity) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_sales_price) AS avg_price
    FROM
        web_sales ws
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 365 FROM date_dim d) 
    GROUP BY
        ws.ws_sold_date_sk,
        ws.ws_item_sk
),
CustomerData AS (
    SELECT
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        hd.hd_buy_potential
    FROM
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
RankedSales AS (
    SELECT
        sd.ws_item_sk,
        sd.total_sales,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.hd_buy_potential,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY sd.total_sales DESC) AS sales_rank
    FROM
        SalesData sd
    JOIN CustomerData cd ON sd.ws_item_sk = (
        SELECT ws_item_sk 
        FROM web_sales 
        WHERE ws_ship_customer_sk = cd.c_customer_sk
        LIMIT 1
    )
)
SELECT 
    r.ws_item_sk,
    r.total_sales,
    r.cd_gender,
    r.cd_marital_status,
    r.hd_buy_potential,
    CASE
        WHEN r.sales_rank <= 10 THEN 'Top 10 Seller'
        ELSE 'Other'
    END AS seller_category
FROM 
    RankedSales r
WHERE 
    r.cd_gender IS NOT NULL
ORDER BY 
    r.total_sales DESC
; 
