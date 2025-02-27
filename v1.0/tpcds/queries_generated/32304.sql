
WITH RECURSIVE sales_data AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_sales_price) AS total_sales,
        RANK() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_sales_price) DESC) AS sales_rank
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        ws.web_site_id, ws.web_name, d.d_date
),
top_sales AS (
    SELECT
        web_site_id,
        web_name,
        sale_date,
        total_sales
    FROM
        sales_data
    WHERE
        sales_rank <= 10
),
instrumented_sales AS (
    SELECT
        ts.web_site_id,
        ts.web_name,
        ts.sale_date,
        ts.total_sales,
        CASE 
            WHEN ts.total_sales > 1000 THEN 'High'
            WHEN ts.total_sales BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category,
        COALESCE(NULLIF(ts.total_sales - LAG(ts.total_sales) OVER (PARTITION BY ts.web_site_id ORDER BY ts.sale_date), 0), 0) AS sales_difference
    FROM
        top_sales AS ts
)
SELECT
    ia.ib_lower_bound,
    ia.ib_upper_bound,
    COUNT(DISTINCT cs.cs_order_number) AS total_orders,
    SUM(cs.cs_ext_sales_price) AS total_revenue,
    AVG(ts.total_sales) AS average_sales_per_web_site
FROM
    inventory AS i
JOIN
    catalog_sales AS cs ON i.inv_item_sk = cs.cs_item_sk
JOIN
    item AS itm ON cs.cs_item_sk = itm.i_item_sk
LEFT JOIN
    income_band AS ia ON ia.ib_income_band_sk = (SELECT hd.hd_income_band_sk FROM household_demographics AS hd WHERE hd.hd_demo_sk = cim.c_current_hdemo_sk)
LEFT JOIN
    instrumented_sales AS ts ON ts.web_site_id = ia.ib_income_band_sk
GROUP BY
    ia.ib_lower_bound, ia.ib_upper_bound
ORDER BY
    total_revenue DESC
FETCH FIRST 5 ROWS ONLY;
