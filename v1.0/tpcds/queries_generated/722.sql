
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.web_site_id,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_net_profit,
        RANK() OVER (PARTITION BY ws.web_site_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales AS ws
    JOIN 
        item AS i ON ws.ws_item_sk = i.i_item_sk
    WHERE 
        i.i_current_price > 10.00
    GROUP BY 
        ws.web_site_sk, ws.web_site_id
), CustomerReturns AS (
    SELECT 
        wr.wr_returning_customer_sk,
        COUNT(DISTINCT wr.wr_order_number) AS total_returns
    FROM 
        web_returns AS wr
    GROUP BY 
        wr.wr_returning_customer_sk
), CustomerDemographicsData AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        hd.hd_income_band_sk,
        COALESCE(hd.hd_buy_potential, 'UNKNOWN') AS buy_potential,
        ROUND(AVG(cd.cd_purchase_estimate), 2) AS avg_purchase_estimate
    FROM 
        customer_demographics AS cd
    LEFT JOIN 
        household_demographics AS hd ON cd.cd_demo_sk = hd.hd_demo_sk
    GROUP BY 
        cd.cd_demo_sk, cd.cd_gender, hd.hd_income_band_sk
)
SELECT 
    cs.c_customer_sk,
    cs.c_first_name,
    cs.c_last_name,
    cd.cd_gender,
    cd.buy_potential,
    cd.avg_purchase_estimate,
    COALESCE(cr.total_returns, 0) AS return_count,
    rs.total_net_profit,
    rs.total_quantity,
    rs.profit_rank
FROM 
    customer AS cs
JOIN 
    CustomerDemographicsData AS cd ON cs.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerReturns AS cr ON cs.c_customer_sk = cr.wr_returning_customer_sk
JOIN 
    RankedSales AS rs ON cs.c_current_addr_sk = rs.web_site_sk
WHERE 
    cs.c_birth_year BETWEEN 1980 AND 1990
    AND (cd.cd_gender = 'M' OR cd.buy_potential != 'UNKNOWN')
ORDER BY 
    rs.total_net_profit DESC, cs.c_last_name ASC;
