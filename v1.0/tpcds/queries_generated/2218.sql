
WITH CustomerReturns AS (
    SELECT 
        cr.returning_customer_sk,
        SUM(cr.return_amount) AS total_return_amount,
        COUNT(cr.return_order_number) AS return_count,
        AVG(cr.returned_quantity) AS avg_return_quantity
    FROM 
        catalog_returns cr
    GROUP BY 
        cr.returning_customer_sk
),
StoreSalesSummary AS (
    SELECT 
        ss.store_sk,
        SUM(ss.net_profit) AS total_net_profit,
        SUM(ss.quantity) AS total_quantity_sold,
        AVG(ss.sales_price) AS avg_sales_price
    FROM 
        store_sales ss
    GROUP BY 
        ss.store_sk
),
WebSalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.net_profit) AS total_net_profit_web,
        COUNT(DISTINCT ws.order_number) AS total_orders_web
    FROM 
        web_sales ws
    GROUP BY 
        ws.web_site_sk
),
Demographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        ca.ca_state,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
)
SELECT 
    d.c_customer_sk,
    d.cd_gender,
    d.cd_marital_status,
    d.cd_credit_rating,
    d.ca_state,
    COALESCE(CR.total_return_amount, 0) AS total_returns,
    COALESCE(SUM(CS.total_net_profit), 0) AS total_store_net_profit,
    COALESCE(WS.total_net_profit_web, 0) AS total_web_net_profit,
    ROW_NUMBER() OVER (PARTITION BY d.ca_state ORDER BY COALESCE(CR.total_return_amount, 0) DESC) AS rank_by_return
FROM 
    Demographics d
LEFT JOIN 
    CustomerReturns CR ON d.c_customer_sk = CR.returning_customer_sk
LEFT JOIN 
    StoreSalesSummary CS ON d.c_customer_sk = CS.store_sk
LEFT JOIN 
    WebSalesSummary WS ON d.c_customer_sk = WS.web_site_sk
WHERE 
    (d.cd_gender = 'F' AND d.cd_marital_status = 'M')
    OR (d.income_band BETWEEN 1 AND 3)
GROUP BY 
    d.c_customer_sk, d.cd_gender, d.cd_marital_status, d.cd_credit_rating, d.ca_state, CR.total_return_amount, WS.total_net_profit_web
ORDER BY 
    total_returns DESC, total_store_net_profit DESC;
