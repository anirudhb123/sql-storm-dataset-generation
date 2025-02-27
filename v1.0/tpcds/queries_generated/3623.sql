
WITH SalesSummary AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        AVG(ws.ws_sales_price) AS avg_sales_price,
        COUNT(ws.ws_item_sk) AS total_items_sold
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2023
    GROUP BY 
        ws.web_site_id
), 
CustomerDetails AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        hd.hd_income_band_sk,
        hd.hd_buy_potential
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON cd.cd_demo_sk = hd.hd_demo_sk
), 
ReturnStatistics AS (
    SELECT 
        wr_returning_customer_sk,
        SUM(wr_return_amt) AS total_return_amt,
        COUNT(wr_order_number) AS return_count
    FROM 
        web_returns
    GROUP BY 
        wr_returning_customer_sk
)
SELECT 
    cs.c_customer_sk,
    cs.cd_gender,
    cs.cd_marital_status,
    cs.hd_income_band_sk,
    cs.hd_buy_potential,
    ss.total_profit,
    ss.total_orders,
    ss.avg_sales_price,
    rs.total_return_amt,
    rs.return_count,
    CASE 
        WHEN ss.total_profit IS NULL THEN 'No Sales'
        ELSE 
            CASE 
                WHEN ss.total_profit > 1000 THEN 'High Value Customer'
                WHEN ss.total_profit BETWEEN 500 AND 1000 THEN 'Medium Value Customer'
                ELSE 'Low Value Customer'
            END 
    END AS customer_value_category
FROM 
    CustomerDetails cs
LEFT JOIN 
    SalesSummary ss ON cs.c_customer_sk = ss.web_site_id
LEFT JOIN 
    ReturnStatistics rs ON cs.c_customer_sk = rs.wr_returning_customer_sk
WHERE 
    (cs.hd_income_band_sk IS NOT NULL OR cs.cd_marital_status = 'M')
AND 
    COALESCE(ss.total_profit, 0) > 0
ORDER BY 
    ss.total_profit DESC NULLS LAST;
