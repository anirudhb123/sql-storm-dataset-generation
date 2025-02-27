
WITH RECURSIVE IncomeHierarchy AS (
    SELECT DISTINCT hd_income_band_sk, hd_buy_potential, hd_dep_count
    FROM household_demographics
    WHERE hd_dep_count > 0
    UNION ALL
    SELECT hh.hd_income_band_sk, hh.hd_buy_potential, hh.hd_dep_count
    FROM household_demographics hh
    JOIN IncomeHierarchy ih ON hh.hd_income_band_sk = ih.hd_income_band_sk
    WHERE hh.hd_dep_count < ih.hd_dep_count
),
SalesData AS (
    SELECT 
        ws_ship_date_sk,
        item.i_item_id,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid_inc_tax) AS total_sales,
        SUM(ws_net_paid_inc_tax) - SUM(ws_ext_discount_amt) AS net_sales
    FROM web_sales 
    JOIN item ON item.i_item_sk = web_sales.ws_item_sk
    GROUP BY ws_ship_date_sk, item.i_item_id
),
DailySales AS (
    SELECT 
        dd.d_date,
        sd.total_quantity,
        sd.total_sales,
        sd.net_sales,
        ROW_NUMBER() OVER (PARTITION BY dd.d_date ORDER BY sd.total_sales DESC) AS sales_rank
    FROM date_dim dd
    LEFT JOIN SalesData sd ON dd.d_date_sk = sd.ws_ship_date_sk
    WHERE dd.d_date >= '2023-01-01' AND dd.d_date <= '2023-12-31'
),
BestSellingItems AS (
    SELECT 
        d.d_date,
        di.i_item_id,
        di.total_quantity,
        di.total_sales,
        di.net_sales
    FROM DailySales di
    JOIN date_dim d ON di.d_date = d.d_date
    WHERE di.sales_rank <= 10
)
SELECT 
    bh.hd_income_band_sk,
    bh.hd_buy_potential,
    COALESCE(BestSelling.total_quantity, 0) AS best_selling_quantity,
    COALESCE(BestSelling.total_sales, 0) AS best_selling_sales
FROM IncomeHierarchy bh
LEFT JOIN (
    SELECT 
        i.i_item_id,
        SUM(ds.total_quantity) AS total_quantity,
        SUM(ds.net_sales) AS total_sales
    FROM BestSellingItems ds
    JOIN item i ON ds.i_item_id = i.i_item_id
    GROUP BY i.i_item_id
) AS BestSelling ON bh.hd_income_band_sk = BestSelling.hd_income_band_sk
ORDER BY bh.hd_income_band_sk;
