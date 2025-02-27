
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        cr.returning_cdemo_sk,
        COUNT(cr.return_quantity) AS total_returns,
        SUM(cr.return_amount) AS total_return_amount
    FROM 
        catalog_returns cr
    WHERE 
        cr.returned_date_sk IS NOT NULL
    GROUP BY 
        cr.returning_customer_sk, 
        cr.returning_cdemo_sk
),
SalesData AS (
    SELECT 
        ws.bill_customer_sk,
        SUM(ws.net_profit) AS total_sales_profit,
        COUNT(ws.order_number) AS total_orders,
        AVG(ws.net_paid_inc_tax) AS avg_order_value
    FROM 
        web_sales ws
    GROUP BY 
        ws.bill_customer_sk
),
Demographics AS (
    SELECT 
        ca.ca_address_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        ib.ib_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer_address ca
    INNER JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
)
SELECT 
    d.cd_gender,
    d.cd_marital_status,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(sd.total_sales_profit, 0) AS total_sales_profit,
    COUNT(DISTINCT d.ca_address_sk) AS customer_count,
    AVG(sd.avg_order_value) AS avg_order_value,
    CASE 
        WHEN COUNT(DISTINCT d.ca_address_sk) > 100 THEN 'High Engagement'
        WHEN COUNT(DISTINCT d.ca_address_sk) BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS engagement_status
FROM 
    Demographics d
LEFT JOIN 
    CustomerReturns cr ON d.ca_address_sk = cr.returning_customer_sk
LEFT JOIN 
    SalesData sd ON d.ca_address_sk = sd.bill_customer_sk
GROUP BY 
    d.cd_gender, 
    d.cd_marital_status
ORDER BY 
    total_returns DESC, 
    total_sales_profit DESC
FETCH FIRST 10 ROWS ONLY;
