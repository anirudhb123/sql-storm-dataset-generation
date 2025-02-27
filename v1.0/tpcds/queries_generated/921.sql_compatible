
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        COUNT(DISTINCT cr.return_order_number) AS total_returns,
        SUM(cr.return_amount) AS total_returned_amount,
        SUM(cr.return_ship_cost) AS total_shipping_cost
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        cr.returning_customer_sk
),
WebSalesData AS (
    SELECT 
        ws.ship_customer_sk,
        SUM(ws.ws_sales_price) AS total_sales_amount,
        COUNT(DISTINCT ws_order_number) AS total_orders
    FROM 
        web_sales ws
    INNER JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2023
    GROUP BY 
        ws.ship_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    LEFT JOIN 
        income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
)
SELECT 
    cd.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(CR.total_returns, 0) AS total_returns,
    COALESCE(CR.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(WS.total_sales_amount, 0) AS total_sales_amount,
    COALESCE(WS.total_orders, 0) AS total_orders,
    CASE 
        WHEN COALESCE(CR.total_returns, 0) > 0 THEN 'Frequent Returner'
        WHEN COALESCE(WS.total_orders, 0) > 10 THEN 'High Value Customer'
        ELSE 'Regular Customer'
    END AS customer_type
FROM 
    CustomerDemographics cd
LEFT JOIN 
    CustomerReturns CR ON cd.c_customer_id = CR.returning_customer_sk
LEFT JOIN 
    WebSalesData WS ON cd.c_customer_id = WS.ship_customer_sk
WHERE 
    (cd.cd_gender = 'F' AND cd.cd_marital_status = 'M') OR (cd.ib_lower_bound <= 50000 AND cd.ib_upper_bound >= 100000)
ORDER BY 
    total_sales_amount DESC, total_returns DESC;
