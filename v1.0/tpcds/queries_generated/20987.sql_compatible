
WITH RankedSales AS (
    SELECT 
        ws_bill_customer_sk,
        ws_item_sk,
        ws_order_number,
        ROW_NUMBER() OVER (PARTITION BY ws_bill_customer_sk ORDER BY ws_net_profit DESC) AS rnk,
        SUM(ws_quantity) OVER (PARTITION BY ws_bill_customer_sk) AS total_quantity,
        SUM(ws_net_profit) OVER (PARTITION BY ws_bill_customer_sk) AS total_net_profit
    FROM 
        web_sales
    WHERE 
        ws_net_profit IS NOT NULL
),
FilteredReturns AS (
    SELECT 
        wr_returning_customer_sk,
        COUNT(*) AS total_returns,
        SUM(wr_return_amt_inc_tax) AS total_return_amount
    FROM 
        web_returns
    WHERE 
        wr_reason_sk IS NOT NULL
    GROUP BY 
        wr_returning_customer_sk
),
CustomerAnalysis AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(cd.cd_gender, 'Unknown') AS gender,
        COALESCE(hd.hd_income_band_sk, 0) AS income_band,
        COALESCE(rs.total_net_profit, 0) AS total_net_profit,
        COALESCE(fr.total_returns, 0) AS total_returns,
        CASE 
            WHEN rs.total_net_profit > 5000 THEN 'High Value'
            WHEN rs.total_net_profit BETWEEN 1000 AND 5000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_category
    FROM 
        customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    LEFT JOIN FilteredReturns fr ON c.c_customer_sk = fr.wr_returning_customer_sk
)
SELECT 
    ca.ca_country,
    COUNT(DISTINCT c.c_customer_sk) AS customer_count,
    AVG(ca.ca_gmt_offset) AS avg_gmt_offset,
    SUM(CASE WHEN ca.ca_state IS NULL THEN 1 ELSE 0 END) AS null_state_count,
    SUM(CASE WHEN ca.ca_state IS NOT NULL AND ca.ca_country = 'USA' THEN 1 ELSE 0 END) AS usa_state_count,
    COUNT(DISTINCT CASE WHEN ca.ca_country = 'Canada' THEN ca.ca_address_sk END) AS canadian_addresses,
    STRING_AGG(DISTINCT ca.ca_city, ', ') AS unique_cities,
    COUNT(CASE WHEN value_category = 'High Value' THEN 1 END) AS high_value_customers,
    COUNT(CASE WHEN value_category = 'Medium Value' THEN 1 END) AS medium_value_customers,
    COUNT(CASE WHEN value_category = 'Low Value' THEN 1 END) AS low_value_customers
FROM 
    customer_address ca
JOIN 
    CustomerAnalysis c ON ca.ca_address_sk = c.c_current_addr_sk
GROUP BY 
    ca.ca_country
ORDER BY 
    customer_count DESC
LIMIT 10;
