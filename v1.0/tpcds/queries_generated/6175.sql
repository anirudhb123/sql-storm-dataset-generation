
WITH sales_data AS (
    SELECT
        DATE(d.d_date) AS sale_date,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        cd.cd_gender,
        ib.ib_income_band_sk
    FROM
        web_sales ws
        JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
        JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        d.d_year BETWEEN 2022 AND 2023
    GROUP BY
        sale_date, cd.cd_gender, ib.ib_income_band_sk
),
store_data AS (
    SELECT
        ss.s_store_sk,
        SUM(ss.ss_quantity) AS total_quantity_store,
        SUM(ss.ss_ext_sales_price) AS total_sales_store
    FROM
        store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE
        ss.ss_sold_date_sk IN (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year BETWEEN 2022 AND 2023)
    GROUP BY
        ss.s_store_sk
)
SELECT
    sd.sale_date,
    sd.cd_gender,
    sd.ib_income_band_sk,
    sd.total_quantity,
    sd.total_sales,
    sd.order_count,
    st.total_quantity_store,
    st.total_sales_store
FROM
    sales_data sd
LEFT JOIN store_data st ON sd.sale_date = st.sale_date
ORDER BY
    sd.sale_date, sd.total_sales DESC;
