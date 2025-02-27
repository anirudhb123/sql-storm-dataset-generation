
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS sales_rank
    FROM
        web_sales ws
    JOIN
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE
        cd.cd_gender = 'F'
        AND cd.cd_marital_status = 'M'
        AND cd.cd_buying_potential IS NOT NULL
    GROUP BY
        ws.web_site_sk
),
SalesSummary AS (
    SELECT
        w.w_warehouse_name,
        r.r_reason_desc,
        COALESCE(SUM(CASE WHEN ws.ws_net_profit > 0 THEN 1 ELSE 0 END), 0) AS profitable_sales,
        COALESCE(SUM(CASE WHEN ws.ws_net_profit < 0 THEN 1 ELSE 0 END), 0) AS unprofitable_sales
    FROM
        RankedSales rs
    JOIN
        store s ON s.s_store_sk = rs.web_site_sk
    LEFT JOIN
        store_returns sr ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN
        web_sales ws ON ws.ws_web_site_sk = s.s_store_sk
    GROUP BY
        w.w_warehouse_name, r.r_reason_desc
)
SELECT
    w.w_warehouse_name,
    SUM(ss.profitable_sales) AS total_profitable_sales,
    SUM(ss.unprofitable_sales) AS total_unprofitable_sales,
    COUNT(DISTINCT ss.r_reason_desc) AS distinct_reasons
FROM
    SalesSummary ss
JOIN
    warehouse w ON ss.w_warehouse_name = w.w_warehouse_name
GROUP BY
    w.w_warehouse_name
HAVING
    SUM(ss.profitable_sales) > 0
ORDER BY
    total_profitable_sales DESC, total_unprofitable_sales ASC;
