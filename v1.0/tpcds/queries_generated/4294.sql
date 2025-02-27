
WITH sales_summary AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid_inc_tax) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid_inc_tax) DESC) AS sales_rank
    FROM 
        web_sales AS ws
    JOIN 
        date_dim AS dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023 AND 
        dd.d_moy BETWEEN 1 AND 6
    GROUP BY 
        ws.ws_item_sk
),
item_info AS (
    SELECT 
        i.i_item_sk,
        i.i_item_desc,
        i.i_current_price,
        ic.ib_income_band_sk,
        CASE 
            WHEN ic.ib_upper_bound IS NOT NULL AND ic.ib_lower_bound IS NOT NULL THEN
                (ic.ib_upper_bound + ic.ib_lower_bound) / 2
            ELSE NULL
        END AS avg_income_band
    FROM 
        item AS i
    LEFT JOIN 
        household_demographics AS ic ON i.i_item_sk = ic.hd_demo_sk
),
sales_by_income AS (
    SELECT 
        ii.i_item_desc,
        MAX(ii.i_current_price) AS max_price,
        SUM(ss.total_sales) AS total_sales,
        SUM(ss.total_quantity) AS total_quantity
    FROM 
        sales_summary AS ss
    JOIN 
        item_info AS ii ON ss.ws_item_sk = ii.i_item_sk
    WHERE 
        ii.avg_income_band IS NOT NULL
    GROUP BY 
        ii.i_item_desc
)
SELECT 
    sbi.i_item_desc,
    sbi.max_price,
    sbi.total_sales,
    sbi.total_quantity,
    CASE 
        WHEN sbi.total_sales IS NULL THEN 'No Sales'
        WHEN sbi.total_sales > 10000 THEN 'High Sales'
        ELSE 'Regular Sales'
    END AS sales_category
FROM 
    sales_by_income AS sbi
LEFT JOIN 
    promotion AS p ON sbi.total_sales > p.p_response_target
ORDER BY 
    sbi.total_sales DESC
FETCH FIRST 10 ROWS ONLY;
