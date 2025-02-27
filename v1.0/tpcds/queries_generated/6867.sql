
WITH Customer_Sales AS (
    SELECT
        c.c_customer_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS total_orders
    FROM
        customer c
    JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2023
    GROUP BY
        c.c_customer_id
),
Top_Customers AS (
    SELECT
        c.customer_id,
        cs.total_sales,
        cs.total_orders,
        RANK() OVER (ORDER BY cs.total_sales DESC) AS sales_rank
    FROM
        Customer_Sales cs
    JOIN
        customer c ON cs.c_customer_id = c.c_customer_id
),
Sales_By_Demographics AS (
    SELECT
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(cs.total_sales) AS demographic_sales,
        COUNT(cs.total_orders) AS demographic_orders
    FROM
        Top_Customers tc
    JOIN
        customer_demographics cd ON tc.customer_id = cd.cd_demo_sk
    GROUP BY
        cd.cd_gender, cd.cd_marital_status
)
SELECT
    g.cd_gender,
    g.cd_marital_status,
    g.demographic_sales,
    g.demographic_orders,
    ROUND(g.demographic_sales / NULLIF(SUM(g.demographic_sales) OVER (), 0), 2) AS sales_percentage
FROM
    Sales_By_Demographics g
WHERE
    g.demographic_orders > 10
ORDER BY
    g.demographic_sales DESC;
