
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_profit,
        RANK() OVER (PARTITION BY ws_bill_customer_sk ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
CustomerDemographics AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_credit_rating,
        cd.cd_dep_count,
        cd.cd_dep_employed_count,
        CASE 
            WHEN cd.cd_buy_potential IS NULL THEN 'Unknown' 
            ELSE cd.cd_buy_potential 
        END AS buy_potential,
        COALESCE(ib.ib_lower_bound, 0) AS income_lower_bound,
        COALESCE(ib.ib_upper_bound, 999999) AS income_upper_bound
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN 
        income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
FilteredSales AS (
    SELECT 
        ws.*,
        cs.total_profit,
        CASE 
            WHEN cs.total_profit > 1000 THEN 'High Profit'
            WHEN cs.total_profit BETWEEN 500 AND 1000 THEN 'Medium Profit'
            ELSE 'Low Profit' 
        END AS profit_category,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY ws_sales_price DESC) AS price_rank
    FROM 
        web_sales ws 
    LEFT JOIN 
        RankedSales cs ON ws.ws_bill_customer_sk = cs.ws_bill_customer_sk
    WHERE 
        ws_ship_date_sk > 0
)
SELECT 
    DISTINCT ca.ca_city, 
    ca.ca_state, 
    SUM(fs.ws_net_profit) AS cumulative_net_profit,
    COUNT(DISTINCT c.c_customer_sk) AS unique_customers
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON ca.ca_address_sk = c.c_current_addr_sk
JOIN 
    FilteredSales fs ON c.c_customer_sk = fs.ws_bill_customer_sk
WHERE 
    ca.ca_state IS NOT NULL
    AND (ca.ca_city LIKE '%town%' OR ca.ca_country = 'USA')
    AND fs.profit_category = 'High Profit'
    AND EXISTS (
        SELECT 1 
        FROM store_sales ss 
        WHERE ss.ss_item_sk = fs.ws_item_sk 
        AND ss.ss_sales_price > 0 
        AND ss.ss_net_profit < fs.ws_net_profit
    )
GROUP BY 
    ca.ca_city, ca.ca_state
HAVING 
    COUNT(DISTINCT fs.ws_order_number) > 10 
ORDER BY 
    cumulative_net_profit DESC NULLS LAST;
