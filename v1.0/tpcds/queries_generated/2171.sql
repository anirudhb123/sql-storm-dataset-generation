
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) as rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim WHERE d_year = 2023)
),
CustomerReturns AS (
    SELECT 
        cr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(cr_return_amt) AS total_return_amt
    FROM
        catalog_returns
    GROUP BY 
        cr_returning_customer_sk
),
IncomeBandSummary AS (
    SELECT 
        hd.hd_income_band_sk,
        SUM(hd.hd_dep_count) AS total_dependents,
        AVG(hd.hd_vehicle_count) AS avg_vehicles
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        hd.hd_income_band_sk
)
SELECT 
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    RANK() OVER (PARTITION BY cs.cs_item_sk ORDER BY COUNT(DISTINCT cs.cs_order_number) DESC) AS sales_rank,
    COALESCE(cr.total_returns, 0) AS total_returns,
    COALESCE(cr.total_return_amt, 0) AS total_return_amt,
    ibs.total_dependents,
    ibs.avg_vehicles
FROM 
    customer_address ca
JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk 
LEFT JOIN 
    store_sales cs ON c.c_customer_sk = cs.ss_customer_sk
LEFT JOIN 
    CustomerReturns cr ON c.c_customer_sk = cr.cr_returning_customer_sk
JOIN 
    IncomeBandSummary ibs ON c.c_current_hdemo_sk = ibs.hd_income_band_sk
WHERE 
    ca.ca_state = 'CA' 
    AND (cs.ss_sales_price > 100 OR cr.total_returns IS NOT NULL)
GROUP BY 
    ca.ca_address_id, ca.ca_city, ca.ca_state, ibs.total_dependents, ibs.avg_vehicles
ORDER BY 
    sales_rank, ca.ca_city;
