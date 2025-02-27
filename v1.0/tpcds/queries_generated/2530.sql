
WITH RankedSales AS (
    SELECT
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_sales_price DESC) AS rank
    FROM
        web_sales ws
    WHERE
        ws.ws_sales_price IS NOT NULL
        AND ws.ws_quantity > 0
),
TopSales AS (
    SELECT
        rt.web_site_sk,
        rt.ws_order_number,
        rt.ws_sales_price,
        rt.ws_quantity
    FROM
        RankedSales rt
    WHERE
        rt.rank <= 10
),
SalesSummary AS (
    SELECT
        w.warehouse_sk,
        SUM(ts.ws_sales_price) AS total_sales,
        COUNT(ts.ws_order_number) AS total_orders,
        AVG(ts.ws_sales_price) AS avg_sales_price,
        COALESCE(MAX(ts.ws_sales_price), 0) AS max_sales_price
    FROM
        TopSales ts
    JOIN
        warehouse w ON w.warehouse_sk = ts.web_site_sk
    GROUP BY
        w.warehouse_sk
),
SalesByState AS (
    SELECT
        ca.ca_state,
        SUM(ss.total_sales) AS state_sales,
        COUNT(ss.total_orders) AS state_orders,
        AVG(ss.avg_sales_price) AS state_avg_price
    FROM
        SalesSummary ss
    LEFT JOIN
        customer_address ca ON ca.ca_address_sk = ss.warehouse_sk
    GROUP BY
        ca.ca_state
),
SalesAnalysis AS (
    SELECT
        state,
        state_sales,
        state_orders,
        state_avg_price,
        CASE
            WHEN state_sales > 100000 THEN 'High'
            WHEN state_sales BETWEEN 50000 AND 100000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_band
    FROM
        SalesByState
)
SELECT
    s.state,
    s.state_sales,
    s.state_orders,
    s.state_avg_price,
    s.sales_band,
    DENSE_RANK() OVER (ORDER BY s.state_sales DESC) AS rank
FROM
    SalesAnalysis s
ORDER BY
    s.state_sales DESC
LIMIT 20;
