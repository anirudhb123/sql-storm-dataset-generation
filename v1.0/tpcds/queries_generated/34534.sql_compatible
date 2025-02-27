
WITH RECURSIVE sales_trends AS (
    SELECT
        ws.web_site_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        ws.web_site_sk, d.d_year
    UNION ALL
    SELECT
        st.web_site_sk,
        st.d_year + 1,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM
        sales_trends AS st
    JOIN
        web_sales AS ws ON st.web_site_sk = ws.ws_web_site_sk
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        st.d_year < 2025
    GROUP BY
        st.web_site_sk, st.d_year
),
customer_return_stats AS (
    SELECT
        c.c_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_web_returns,
        SUM(wr.wr_return_amt) AS total_return_amount
    FROM
        customer AS c
    LEFT JOIN
        web_returns AS wr ON c.c_customer_sk = wr.wr_returning_customer_sk
    GROUP BY
        c.c_customer_sk
),
top_customers AS (
    SELECT
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(COALESCE(ws.ws_net_profit, 0)) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(COALESCE(ws.ws_net_profit, 0)) DESC) AS rank
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY
        c.c_customer_id, cd.cd_gender, cd.cd_marital_status
),
total_sales AS (
    SELECT
        SUM(ss.ss_net_profit) AS total_store_sales,
        SUM(ws.ws_net_profit) AS total_web_sales,
        SUM(cs.cs_net_profit) AS total_catalog_sales
    FROM
        store_sales AS ss
    FULL OUTER JOIN
        web_sales AS ws ON ss.ss_item_sk = ws.ws_item_sk
    FULL OUTER JOIN
        catalog_sales AS cs ON ss.ss_item_sk = cs.cs_item_sk
)

SELECT
    st.web_site_sk,
    st.d_year,
    st.total_net_profit AS annual_net_profit,
    COALESCE(cus.total_web_returns, 0) AS total_web_returns,
    COALESCE(cus.total_return_amount, 0) AS total_return_amount,
    tc.c_customer_id,
    tc.cd_gender,
    tc.cd_marital_status,
    tc.total_spent,
    tc.total_orders,
    ts.total_store_sales,
    ts.total_web_sales,
    ts.total_catalog_sales
FROM
    sales_trends AS st
LEFT JOIN
    customer_return_stats AS cus ON st.web_site_sk = cus.c_customer_sk
LEFT JOIN
    top_customers AS tc ON cus.c_customer_sk = tc.c_customer_id
CROSS JOIN
    total_sales AS ts
WHERE
    st.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_trends);
