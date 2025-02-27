
WITH RECURSIVE MaxIncome AS (
    SELECT MAX(ib_upper_bound) AS max_income
    FROM income_band
), SeasonalSales AS (
    SELECT 
        d.d_year,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(ws.ws_net_profit) DESC) AS rn
    FROM date_dim d
    JOIN web_sales ws ON d.d_date_sk = ws.ws_sold_date_sk
    WHERE d.d_year BETWEEN 2018 AND 2023
    GROUP BY d.d_year
), CustomerProfits AS (
    SELECT 
        c.c_customer_id,
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        MAX(cd.cd_credit_rating) AS highest_credit_rating
    FROM customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY c.c_customer_id
), QualifiedReturns AS (
    SELECT 
        sr.sr_ticket_number AS return_ticket,
        sr.sr_return_amt,
        ROW_NUMBER() OVER (PARTITION BY sr.sr_ticket_number ORDER BY sr.sr_return_amt DESC) AS return_rank
    FROM store_returns sr
    WHERE sr.sr_return_amt > (SELECT COALESCE(AVG(sr_inner.sr_return_amt), 0) FROM store_returns sr_inner)
)
SELECT 
    c.c_customer_id,
    MAX(cp.total_profit) AS max_profit,
    MAX(ip.full_income_band) AS max_income_band,
    SUM(cs.cs_net_profit) AS total_catalog_sales_profit,
    COALESCE(QUAL.return_ticket, 'No Returns') AS return_ticket,
    COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales_tickets,
    SUM(ws.ws_ext_tax) AS total_sales_tax,
    CEIL(SUM(ws.ws_net_profit) / NULLIF(SUM(ws.ws_quantity), 0)) AS average_profit_per_item
FROM customer c
LEFT JOIN CustomerProfits cp ON c.c_customer_id = cp.c_customer_id
LEFT JOIN (SELECT 
               ib.ib_income_band_sk AS income_band_sk,
               CONCAT(ib.ib_lower_bound, '-', ib.ib_upper_bound) AS full_income_band
           FROM income_band ib) ip ON cp.highest_credit_rating = 
           CASE 
               WHEN cp.total_profit > (SELECT max_income FROM MaxIncome) THEN 'A' 
               ELSE NULL 
           END
LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk 
LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
LEFT JOIN QualifiedReturns QUAL ON ss.ss_ticket_number = QUAL.return_ticket
WHERE 
    c.c_birth_year % 2 = 0 
    AND (c.c_first_name LIKE 'A%' OR c.c_last_name LIKE '%z')
GROUP BY 
    c.c_customer_id, 
    QUAL.return_ticket
HAVING 
    SUM(ws.ws_net_profit) > 5000
ORDER BY max_profit DESC, return_ticket DESC;
