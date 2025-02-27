
WITH YearlySales AS (
    SELECT
        d.d_year,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_profit
    FROM
        web_sales ws
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
),
TopStores AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        SUM(ss.ss_net_paid) AS total_net_sales
    FROM
        store_sales ss
    JOIN
        store s ON ss.ss_store_sk = s.s_store_sk
    GROUP BY
        s.s_store_sk, s.s_store_name
    HAVING
        SUM(ss.ss_net_paid) > (SELECT AVG(total_net_sales) FROM (
            SELECT SUM(ss2.ss_net_paid) AS total_net_sales
            FROM store_sales ss2
            GROUP BY ss2.ss_store_sk) AS sales_avg)
),
CustomerDemographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_income_band_sk,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_income_band_sk
),
TotalDemographicSales AS (
    SELECT
        cd.cd_gender,
        ib.ib_income_band_sk,
        COALESCE(CSUM.total_spent, 0) AS total_spent
    FROM
        income_band ib
    LEFT JOIN
        CustomerDemographics cd ON ib.ib_income_band_sk = cd.cd_income_band_sk
    LEFT JOIN (
        SELECT
            cd_gender,
            cd_income_band_sk,
            SUM(total_spent) AS total_spent
        FROM
            CustomerDemographics
        GROUP BY
            cd_gender, cd_income_band_sk
    ) AS CSUM ON cd.cd_gender = CSUM.cd_gender  
               AND cd.cd_income_band_sk = CSUM.cd_income_band_sk
)
SELECT
    ts.s_store_name,
    ys.d_year,
    COALESCE(ts.total_net_sales, 0) AS store_sales,
    COALESCE(ys.total_sales, 0) AS web_sales,
    COALESCE(ds.total_spent, 0) AS demographic_spending,
    ROW_NUMBER() OVER (PARTITION BY ys.d_year ORDER BY ts.total_net_sales DESC) AS store_rank,
    CASE
        WHEN ys.total_sales > 1000000 THEN 'High Revenue Year'
        WHEN ys.total_sales BETWEEN 500000 AND 1000000 THEN 'Moderate Revenue Year'
        ELSE 'Low Revenue Year'
    END AS revenue_category
FROM
    YearlySales ys
FULL OUTER JOIN
    TopStores ts ON ts.total_net_sales = ys.total_sales
LEFT JOIN
    TotalDemographicSales ds ON ds.cd_gender = 'F'
ORDER BY
    ys.d_year DESC,
    store_rank
LIMIT 50;
