
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rank_profit,
        SUM(ws.ws_quantity) OVER (PARTITION BY ws.ws_item_sk) AS total_quantity,
        SUM(ws.ws_net_paid) OVER (PARTITION BY ws.ws_item_sk) AS total_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk > (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_year = (SELECT MAX(d_year) FROM date_dim))
),

FilteredReturns AS (
    SELECT 
        sr.*, 
        r.r_reason_desc
    FROM 
        store_returns sr 
    LEFT JOIN 
        reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE 
        sr.sr_return_quantity > 0 AND sr.sr_return_amt > 100
),

CustomerIncome AS (
    SELECT 
        cd.cd_demo_sk,
        CASE 
            WHEN h.hd_income_band_sk IS NULL THEN 'Unknown'
            ELSE CONCAT('Income Band: ', ib.ib_lower_bound, ' - ', ib.ib_upper_bound)
        END AS income_band
    FROM 
        customer_demographics cd
    LEFT JOIN 
        household_demographics h ON cd.cd_demo_sk = h.hd_demo_sk
    LEFT JOIN 
        income_band ib ON h.hd_income_band_sk = ib.ib_income_band_sk
)

SELECT
    c.c_first_name,
    c.c_last_name,
    ca.ca_city,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    COUNT(DISTINCT r.r_reason_desc) AS reason_count,
    ci.income_band,
    AVG(rs.total_net_paid) AS avg_net_paid,
    MAX(CASE WHEN rs.rank_profit = 1 THEN rs.total_quantity END) AS highest_quantity_sold
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    FilteredReturns sr ON c.c_customer_sk = sr.sr_customer_sk
LEFT JOIN 
    CustomerIncome ci ON c.c_current_cdemo_sk = ci.cd_demo_sk
LEFT JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_order_number
WHERE 
    ca.ca_state = 'NY'
GROUP BY 
    c.c_first_name, c.c_last_name, ca.ca_city, ci.income_band
HAVING 
    SUM(sr.sr_return_quantity) > 0
ORDER BY 
    avg_net_paid DESC NULLS LAST;
