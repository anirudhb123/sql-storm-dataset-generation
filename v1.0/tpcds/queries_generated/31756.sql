
WITH RECURSIVE sales_summary AS (
    SELECT 
        cs_item_sk, 
        SUM(cs_quantity) AS total_quantity,
        SUM(cs_net_profit) AS total_net_profit,
        SUM(cs_ext_sales_price) AS total_sales_price
    FROM catalog_sales
    GROUP BY cs_item_sk
    UNION ALL
    SELECT 
        cs.cs_item_sk, 
        ss.total_quantity + cs.cs_quantity,
        ss.total_net_profit + cs.cs_net_profit,
        ss.total_sales_price + cs.cs_ext_sales_price
    FROM catalog_sales cs
    JOIN sales_summary ss ON cs.cs_item_sk = ss.cs_item_sk
    WHERE ss.total_quantity < 1000
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        d.d_year,
        cd.cd_gender,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    GROUP BY c.c_customer_sk, d.d_year, cd.cd_gender
),
address_info AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ca.ca_country,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM customer_address ca
    LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY ca.ca_address_sk, ca.ca_city, ca.ca_state, ca.ca_country
)
SELECT 
    ci.c_customer_sk,
    ci.d_year,
    ci.cd_gender,
    a.ca_city,
    a.ca_state,
    a.ca_country,
    a.customer_count,
    ss.total_net_profit
FROM customer_info ci
JOIN address_info a ON ci.c_customer_sk = a.customer_count
LEFT JOIN sales_summary ss ON ci.c_customer_sk = ss.cs_item_sk
WHERE ci.total_net_profit > (SELECT AVG(total_net_profit) FROM customer_info)
AND a.ca_country IS NOT NULL
ORDER BY ci.d_year DESC, ss.total_net_profit DESC;
