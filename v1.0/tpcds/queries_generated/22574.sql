
WITH
    recent_sales AS (
        SELECT
            ws_item_sk,
            SUM(ws_quantity) AS total_quantity,
            SUM(ws_net_paid_inc_tax) AS total_net_income,
            DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rank
        FROM
            web_sales
        GROUP BY
            ws_item_sk
    ),
    sales_summary AS (
        SELECT
            cs.cs_item_sk,
            SUM(cs.cs_quantity) AS catalog_quantity,
            SUM(cs.cs_net_paid_inc_tax) AS catalog_net_income
        FROM
            catalog_sales cs
        GROUP BY
            cs.cs_item_sk
    ),
    income_band_statistics AS (
        SELECT
            hd.hd_income_band_sk,
            COUNT(DISTINCT c.c_customer_sk) AS customer_count,
            AVG(hd.hd_dep_count) AS avg_dep_count
        FROM
            household_demographics hd
        JOIN
            customer c ON hd.hd_demo_sk = c.c_current_hdemo_sk
        GROUP BY
            hd.hd_income_band_sk
    )
    
SELECT
    coalesce(a.i_item_id, b.i_item_id) AS item_id,
    COALESCE(a.total_quantity, 0) AS total_web_quantity,
    COALESCE(b.catalog_quantity, 0) AS total_catalog_quantity,
    COALESCE(a.total_net_income, 0) AS total_web_income,
    COALESCE(b.catalog_net_income, 0) AS total_catalog_income,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    isnull(i.customer_count, 0) AS customer_count,
    CASE 
        WHEN a.total_net_income > 0 THEN 'Web Profit'
        WHEN b.catalog_net_income > 0 THEN 'Catalog Profit'
        ELSE 'No Profit'
    END AS profit_status
FROM
    recent_sales a
FULL OUTER JOIN
    sales_summary b ON a.ws_item_sk = b.cs_item_sk
FULL OUTER JOIN
    income_band ib ON (CASE
        WHEN a.total_net_income IS NOT NULL THEN 
            (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= COALESCE(a.total_net_income, 0) AND ib_upper_bound >= COALESCE(a.total_net_income, 0))
        WHEN b.catalog_net_income IS NOT NULL THEN
            (SELECT ib_income_band_sk FROM income_band WHERE ib_lower_bound <= COALESCE(b.catalog_net_income, 0) AND ib_upper_bound >= COALESCE(b.catalog_net_income, 0))
        ELSE NULL
    END) = ib.ib_income_band_sk
LEFT JOIN
    income_band_statistics i ON ib.ib_income_band_sk = i.hd_income_band_sk
WHERE 
    (a.rank = 1 OR b.cs_item_sk IS NULL) AND
    (i.customer_count IS NULL OR i.customer_count > 5)
ORDER BY 
    item_id DESC, 
    total_web_income DESC, 
    total_catalog_income DESC;
