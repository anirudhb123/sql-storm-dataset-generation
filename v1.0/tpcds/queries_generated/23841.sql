
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws_sales_price DESC) AS rank
    FROM web_sales ws
    WHERE ws_sales_price IS NOT NULL
),
TopSales AS (
    SELECT 
        w.warehouse_sk,
        r.r_reason_desc,
        SUM(rs.ws_sales_price) AS total_sales,
        COUNT(DISTINCT rs.ws_order_number) AS unique_orders
    FROM RankedSales rs
    LEFT JOIN warehouse w ON rs.ws_item_sk = w.warehouse_sk
    LEFT JOIN store_returns sr ON rs.ws_item_sk = sr.sr_item_sk
    LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE rank <= 10
    GROUP BY w.warehouse_sk, r.r_reason_desc
),
IncomeBandSummary AS (
    SELECT 
        ib.ib_income_band_sk, 
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN household_demographics hd ON c.c_current_cdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_demographics cd ON c.c_current_hdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year IS NOT NULL AND hd.hd_buy_potential IS NOT NULL
    GROUP BY ib.ib_income_band_sk
)
SELECT 
    T.warehouse_sk,
    T.r_reason_desc,
    T.total_sales,
    T.unique_orders,
    I.avg_purchase_estimate,
    CASE
        WHEN I.customer_count > 0 THEN 
            ROUND(T.total_sales / NULLIF(I.customer_count, 0), 2)
        ELSE 
            NULL 
    END AS sales_per_customer
FROM TopSales T
FULL OUTER JOIN IncomeBandSummary I ON T.warehouse_sk = I.ib_income_band_sk
ORDER BY T.total_sales DESC NULLS LAST, sales_per_customer DESC;
