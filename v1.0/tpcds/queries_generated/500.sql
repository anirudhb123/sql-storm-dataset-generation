
WITH SalesData AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_sales_price,
        MIN(ws.ws_sales_price) AS min_sales_price,
        COUNT(DISTINCT w.w_warehouse_sk) AS total_warehouses
    FROM
        web_sales ws
    JOIN
        web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE
        ws.ws_sold_date_sk BETWEEN 2459591 AND 2459651
    GROUP BY
        ws.web_site_sk
),
TopSales AS (
    SELECT 
        web_site_sk,
        total_profit,
        total_orders,
        max_sales_price,
        min_sales_price,
        total_warehouses,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS sales_rank
    FROM
        SalesData
),
CustomerReturns AS (
    SELECT 
        wr.refunded_customer_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(wr.wr_order_number) AS total_returns
    FROM 
        web_returns wr
    GROUP BY 
        wr.refunded_customer_sk
),
CustomerDemographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cb.hd_income_band_sk
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics cb ON cd.cd_demo_sk = cb.hd_demo_sk
)
SELECT 
    ts.web_site_sk,
    ts.total_profit,
    ts.total_orders,
    ts.max_sales_price,
    ts.min_sales_price,
    ts.total_warehouses,
    cr.total_return_loss,
    cr.total_returns,
    CASE 
        WHEN cd.cd_gender = 'M' THEN 'Male'
        WHEN cd.cd_gender = 'F' THEN 'Female'
        ELSE 'Other'
    END AS gender_description,
    CASE 
        WHEN cr.total_return_loss IS NULL THEN 'No Returns'
        WHEN cr.total_return_loss > 500 THEN 'High Loss'
        ELSE 'Moderate Loss'
    END AS return_loss_category
FROM 
    TopSales ts
LEFT JOIN 
    CustomerReturns cr ON ts.web_site_sk = cr.refunded_customer_sk
LEFT JOIN 
    CustomerDemographics cd ON ts.web_site_sk = cd.cd_demo_sk
WHERE 
    ts.sales_rank <= 10
ORDER BY 
    ts.total_profit DESC;
