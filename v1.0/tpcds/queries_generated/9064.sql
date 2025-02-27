
WITH sales_summary AS (
    SELECT
        ws.sold_date_sk,
        SUM(ws.ext_sales_price) AS total_sales,
        COUNT(DISTINCT ws.order_number) AS total_orders,
        AVG(ws.net_profit) AS average_profit,
        ds.d_year
    FROM
        web_sales AS ws
    JOIN
        date_dim AS ds ON ws.sold_date_sk = ds.d_date_sk
    WHERE
        ds.d_year >= 2015
    GROUP BY
        ws.sold_date_sk, ds.d_year
),
customer_summary AS (
    SELECT
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        SUM(cd.cd_purchase_estimate) AS total_purchase_estimate,
        AVG(cd.cd_credit_rating) AS average_credit_rating
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender
)
SELECT
    ss.d_year,
    sum(ss.total_sales) AS yearly_sales,
    sum(ss.total_orders) AS total_orders,
    cs.cd_gender,
    cs.customer_count,
    cs.total_purchase_estimate,
    cs.average_credit_rating
FROM
    sales_summary AS ss
JOIN
    customer_summary AS cs ON ss.d_year = YEAR(CURRENT_DATE) -- Filter for current year
GROUP BY
    ss.d_year, cs.cd_gender
ORDER BY
    ss.d_year DESC, cs.cd_gender;
