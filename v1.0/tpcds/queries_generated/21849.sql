
WITH RankedSales AS (
    SELECT 
        ws.web_site_id,
        ws_quantity,
        ws_sales_price,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws_quantity DESC) AS rank_sales,
        DENSE_RANK() OVER (PARTITION BY ws.web_site_id ORDER BY ws_sales_price ASC) AS dense_rank_price
    FROM web_sales ws
    JOIN date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE dd.d_year = 2023 AND dd.d_weekend = 'Y'
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_customer_sk = hd.hd_demo_sk
),
ReturnedItems AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returned,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    WHERE sr_returned_date_sk > (
        SELECT MAX(d_date_sk) 
        FROM date_dim 
        WHERE d_year = 2023
    )
    GROUP BY sr_item_sk
),
TopReturns AS (
    SELECT 
        RANK() OVER (ORDER BY total_returned DESC) AS return_rank,
        ri.*
    FROM ReturnedItems ri
),
FinalReport AS (
    SELECT 
        cd.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(rs.ws_quantity) AS total_quantity_sold,
        SUM(rs.ws_sales_price * rs.ws_quantity) AS total_sales_value,
        COUNT(DISTINCT tr.return_rank) AS total_returns_rank
    FROM CustomerDetails cd
    JOIN RankedSales rs ON cd.c_customer_id IN (
        SELECT ws_bill_customer_sk 
        FROM web_sales 
        WHERE ws_ship_date_sk IN (
            SELECT ws_ship_date_sk 
            FROM RankedSales 
            WHERE rank_sales = 1
        )
    )
    LEFT JOIN TopReturns tr ON rs.ws_item_sk = tr.sr_item_sk
    GROUP BY cd.c_customer_id, cd.cd_gender, cd.cd_marital_status
)
SELECT 
    *,
    CASE 
        WHEN total_sales_value IS NULL THEN 'NO SALES'
        WHEN total_quantity_sold > 100 THEN 'HIGH VOLUME'
        ELSE 'VARIABLE VOLUME' 
    END AS sales_category
FROM FinalReport
WHERE income_band IS NOT NULL 
      AND total_returns_rank > 0
ORDER BY sales_category DESC, total_sales_value NULLS LAST;
