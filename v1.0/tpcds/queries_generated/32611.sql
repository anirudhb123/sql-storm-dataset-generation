
WITH RECURSIVE sales_hierarchy AS (
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) DESC) AS rank
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1995
    GROUP BY ws.web_site_sk, ws.web_name
    HAVING SUM(ws.ws_net_profit) > 1000
    UNION ALL
    SELECT 
        ws.web_site_sk,
        ws.web_name,
        SUM(ws.ws_net_profit) + sh.total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_id ORDER BY SUM(ws.ws_net_profit) + sh.total_net_profit DESC) AS rank
    FROM web_sales ws
    JOIN sales_hierarchy sh ON ws.web_site_sk = sh.web_site_sk
    GROUP BY ws.web_site_sk, ws.web_name, sh.total_net_profit
),

customer_stats AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY cd.cd_gender
),

returns_summary AS (
    SELECT 
        sr_return_date,
        COUNT(sr_ticket_number) AS total_returns,
        SUM(sr_return_amt_inc_tax) AS total_return_amt
    FROM store_returns
    WHERE sr_return_quantity > 0
    GROUP BY sr_returned_date_sk
)

SELECT 
    ch.web_name,
    cs.cd_gender,
    cs.customer_count,
    cs.avg_purchase_estimate,
    SUM(rs.total_returns) AS overall_returns,
    SUM(rs.total_return_amt) AS total_return_amount
FROM sales_hierarchy ch
JOIN customer_stats cs ON cs.customer_count > 100
LEFT JOIN returns_summary rs ON DATE(rs.sr_returned_date_sk) BETWEEN '2023-01-01' AND '2023-12-31'
GROUP BY ch.web_name, cs.cd_gender, cs.customer_count, cs.avg_purchase_estimate
ORDER BY overall_returns DESC, ch.web_name;
