
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_order_number,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws_net_sales_price) DESC) AS sales_rank
    FROM (
        SELECT 
            ws.web_site_sk,
            ws_order_number,
            ws_item_sk,
            ws_quantity,
            ws_ext_sales_price AS ws_net_sales_price
        FROM web_sales ws
        WHERE ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
                                  AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    ) AS ws
    GROUP BY ws.web_site_sk, ws_order_number, ws_item_sk
),
TopWebSales AS (
    SELECT 
        web_site_sk,
        ws_order_number,
        total_quantity,
        total_sales
    FROM RankedSales
    WHERE sales_rank <= 5
),
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        c.c_email_address,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
)
SELECT 
    cw.web_site_sk,
    cw.ws_order_number,
    cw.total_quantity,
    cw.total_sales,
    cd.c_email_address,
    cd.cd_gender,
    cd.cd_marital_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound
FROM TopWebSales cw
LEFT JOIN CustomerDetails cd ON cd.c_customer_sk = (
    SELECT DISTINCT ws_ship_customer_sk 
    FROM web_sales 
    WHERE ws_order_number = cw.ws_order_number
)
LEFT JOIN household_demographics hd ON cd.cd_income_band_sk = hd.hd_income_band_sk
LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
WHERE cw.total_sales > 1000
ORDER BY cw.total_sales DESC, cw.total_quantity ASC;
