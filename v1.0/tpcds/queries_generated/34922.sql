
WITH RECURSIVE SalesAggregation AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        SUM(ws_ext_tax) AS total_tax,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk) AS rn
    FROM web_sales
    WHERE ws_sold_date_sk >= (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ws_item_sk
    UNION ALL
    SELECT 
        sa.ws_item_sk,
        sa.total_quantity + COALESCE(wr.total_quantity, 0),
        sa.total_sales + COALESCE(wr.total_sales, 0),
        sa.total_tax + COALESCE(wr.total_tax, 0),
        ROW_NUMBER() OVER (PARTITION BY sa.ws_item_sk ORDER BY sa.total_sales DESC) AS rn
    FROM SalesAggregation sa
    LEFT JOIN (
        SELECT 
            wr_item_sk,
            SUM(wr_return_quantity) AS total_quantity,
            SUM(wr_return_amt_inc_tax) AS total_sales,
            SUM(wr_return_tax) AS total_tax
        FROM web_returns
        GROUP BY wr_item_sk
    ) wr ON sa.ws_item_sk = wr.wr_item_sk
    WHERE sa.rn < 5
)
SELECT 
    i.i_item_id,
    i.i_item_desc,
    COALESCE(sa.total_quantity, 0) AS total_sold_quantity,
    COALESCE(sa.total_sales, 0) AS total_sales_value,
    COALESCE(sa.total_tax, 0) AS total_tax_collected
FROM item i
LEFT JOIN SalesAggregation sa ON i.i_item_sk = sa.ws_item_sk
WHERE i.i_current_price > 20.00
ORDER BY total_sales_value DESC
LIMIT 10;

SELECT * FROM (
    SELECT 
        ca_state,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_address ca ON s.s_street_number = ca.ca_street_number
    WHERE ss_ss_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim WHERE d_year = 2023) 
    AND (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY ca_state
    HAVING SUM(ss_net_profit) > 5000
) AS StateProfit
UNION ALL
SELECT 
    ca_country,
    AVG(ss_net_profit) AS average_profit
FROM store_sales ss
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN customer_address ca ON s.s_street_number = ca.ca_street_number
GROUP BY ca_country
HAVING AVG(ss_net_profit) > 1000
ORDER BY average_profit DESC;

WITH RankedCustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd_gender ORDER BY cd_credit_rating DESC) AS rank
    FROM customer_demographics
)
SELECT 
    r.cd_gender,
    r.cd_marital_status,
    COUNT(*) AS customer_count
FROM RankedCustomerDemographics r
WHERE r.rank <= 10
GROUP BY r.cd_gender, r.cd_marital_status
HAVING COUNT(*) > 5;
