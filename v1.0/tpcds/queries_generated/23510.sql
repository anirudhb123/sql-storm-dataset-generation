
WITH RankedReturns AS (
    SELECT 
        CASE 
            WHEN sr_returned_date_sk IS NOT NULL THEN 'Store'
            WHEN wr_returned_date_sk IS NOT NULL THEN 'Web'
            ELSE 'Unknown'
        END AS Return_Type,
        COALESCE(SUM(sr_return_quantity), 0) AS Total_Store_Returns,
        COALESCE(SUM(wr_return_quantity), 0) AS Total_Web_Returns,
        ROW_NUMBER() OVER (PARTITION BY CASE 
                                             WHEN sr_returned_date_sk IS NOT NULL THEN 1
                                             ELSE 2
                                         END 
                           ORDER BY 
                               COALESCE(SUM(sr_return_quantity), 0) DESC) AS Rank
    FROM 
        store_returns sr
    FULL OUTER JOIN 
        web_returns wr ON sr_item_sk = wr_item_sk
    GROUP BY 
        sr_returned_date_sk, wr_returned_date_sk
),
IncomeDemographics AS (
    SELECT 
        hd_demo_sk,
        ib_income_band_sk,
        CASE 
            WHEN NOT (ib_lower_bound IS NULL AND ib_upper_bound IS NULL) THEN 
                CONCAT('Income range: ', COALESCE(CONVERT(VARCHAR, ib_lower_bound), 'Unknown'), 
                       ' to ', COALESCE(CONVERT(VARCHAR, ib_upper_bound), 'Unknown'))
            ELSE 'No income data available'
        END AS Income_Range
    FROM 
        household_demographics hd
    LEFT JOIN 
        income_band ib ON hd_income_band_sk = ib.income_band_sk
    WHERE 
        hd_buy_potential = 'High'
    ORDER BY 
        hd_demo_sk
)
SELECT 
    c.c_customer_id,
    ca.ca_city,
    d.d_date,
    SUM(ws.net_profit) AS Total_Profit,
    SUM(COALESCE(sr_return_amt, 0) + COALESCE(wr_return_amt, 0)) AS Total_Returns,
    COUNT(*) FILTER (WHERE Return_Type = 'Store') AS Store_Return_Records,
    COUNT(*) FILTER (WHERE Return_Type = 'Web') AS Web_Return_Records,
    ROW_NUMBER() OVER (PARTITION BY ca.ca_city ORDER BY SUM(ws.net_profit) DESC) as City_Rank,
    CONCAT(Income_Range, ' for customer demo: ', id.id_demo_sk) AS Income_Status
FROM 
    customer c
JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
JOIN 
    web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
FULL OUTER JOIN 
    RankedReturns rr ON rr.Return_Type = 
        CASE 
            WHEN ws.ws_ship_date_sk IS NOT NULL THEN 'Web' 
            ELSE 'Store'
        END
LEFT JOIN 
    IncomeDemographics id ON c.c_current_cdemo_sk = id.hd_demo_sk
JOIN 
    date_dim d ON d.d_date_sk = ws.ws_sold_date_sk
WHERE 
    d.d_year = 2023 AND 
    (c.c_birth_month IS NOT NULL OR c.c_birth_day IS NOT NULL) AND 
    (c.c_preferred_cust_flag = 'Y' OR (c.c_first_name LIKE 'A%' AND c.c_last_name LIKE '%son'))
GROUP BY 
    c.c_customer_id, ca.ca_city, d.d_date, id.id_demo_sk, Income_Range
HAVING 
    SUM(ws.net_profit) > 1000
ORDER BY 
    Total_Profit DESC, ca.ca_city;
