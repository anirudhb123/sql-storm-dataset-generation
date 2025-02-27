
WITH RECURSIVE TopSellingItems AS (
    SELECT
        ss_item_sk,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_paid) AS total_sales,
        ROW_NUMBER() OVER (ORDER BY SUM(ss_net_paid) DESC) AS rank
    FROM
        store_sales
    GROUP BY
        ss_item_sk
), 
HighValueCustomers AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        SUM(ws.ws_net_paid) AS total_spent
    FROM
        customer AS c
    JOIN
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE
        ws.ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2022) - 365
    GROUP BY
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
    HAVING
        SUM(ws.ws_net_paid) > 1000
), 
SalesTrends AS (
    SELECT
        d.d_year,
        SUM(ws.ws_net_profit) AS total_profit,
        AVG(ws.ws_net_paid_inc_tax) AS avg_order_value,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM
        web_sales AS ws
    JOIN
        date_dim AS d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        d.d_year
), 
CombinedStatistics AS (
    SELECT 
        hvc.c_first_name || ' ' || hvc.c_last_name AS customer_name,
        hvc.cd_gender,
        tsi.total_quantity,
        tsi.total_sales,
        st.total_profit,
        st.avg_order_value,
        st.total_orders
    FROM
        HighValueCustomers AS hvc
    LEFT JOIN
        TopSellingItems AS tsi ON hvc.c_customer_sk IN (SELECT ws_ship_customer_sk FROM web_sales WHERE ws_item_sk IN (SELECT ss_item_sk FROM store_sales))
    CROSS JOIN
        SalesTrends AS st
)
SELECT 
    customer_name,
    cd_gender,
    COALESCE(total_quantity, 0) AS total_quantity,
    COALESCE(total_sales, 0) AS total_sales,
    total_profit,
    avg_order_value,
    total_orders
FROM 
    CombinedStatistics
ORDER BY 
    total_sales DESC, total_quantity DESC
LIMIT 10;
