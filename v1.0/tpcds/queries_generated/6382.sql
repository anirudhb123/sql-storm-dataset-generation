
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk
),
ItemDetails AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        CASE 
            WHEN id.ib_income_band_sk IS NOT NULL THEN id.ib_upper_bound 
            ELSE NULL 
        END AS income_band
    FROM 
        item i
    LEFT JOIN 
        inventory inv ON i.i_item_sk = inv.inv_item_sk
    LEFT JOIN 
        household_demographics id ON i.i_item_sk = id.hd_demo_sk AND id.hd_income_band_sk IS NOT NULL
)
SELECT 
    d.d_year,
    COUNT(DISTINCT ish.ws_item_sk) AS total_items_sold,
    SUM(ish.total_sales) AS total_sales_value,
    AVG(ish.total_sales) AS average_sales_value,
    MAX(ish.total_sales) AS max_sales_value,
    MIN(ish.total_sales) AS min_sales_value,
    id.i_item_desc,
    id.income_band
FROM 
    RankedSales ish
JOIN 
    ItemDetails id ON ish.ws_item_sk = id.i_item_sk
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(ws_sold_date_sk) FROM web_sales WHERE ws_item_sk = ish.ws_item_sk)
WHERE 
    ish.sales_rank <= 10
GROUP BY 
    d.d_year, id.i_item_desc, id.income_band
ORDER BY 
    total_sales_value DESC;
