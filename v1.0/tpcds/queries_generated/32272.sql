
WITH RECURSIVE Sales_CTE AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_ext_sales_price) DESC) AS rank
    FROM
        web_sales
    WHERE
        ws_sold_date_sk BETWEEN 1 AND 30
    GROUP BY
        ws_item_sk
),
Top_Sales AS (
    SELECT
        item.i_item_id,
        item.i_item_desc,
        sales.total_sales
    FROM
        Sales_CTE sales
    JOIN
        item ON sales.ws_item_sk = item.i_item_sk
    WHERE
        sales.rank <= 10
),
Revenue_Summary AS (
    SELECT
        SUM(total_sales) AS total_revenue,
        AVG(total_sales) AS average_revenue
    FROM
        Top_Sales
),
Customer_Demographics AS (
    SELECT
        cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM
        customer c
    JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY
        cd_gender
)
SELECT
    ts.i_item_id,
    ts.i_item_desc,
    ts.total_sales,
    rd.total_revenue,
    rd.average_revenue,
    cd.gender,
    cd.customer_count
FROM
    Top_Sales ts
LEFT JOIN
    Revenue_Summary rd ON 1=1
JOIN
    Customer_Demographics cd ON cd.customer_count > 10
ORDER BY
    ts.total_sales DESC;
