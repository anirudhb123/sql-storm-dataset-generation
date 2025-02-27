
WITH recursive customer_data AS (
    SELECT c.c_customer_sk, c.c_customer_id, c.c_current_cdemo_sk, cd.cd_gender, cd.cd_marital_status,
           ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY c.c_birth_year DESC) AS rn,
           COALESCE(CAST(NULLIF(c.c_email_address, '') AS VARCHAR(50)), 'No Email') AS email,
           COUNT(hd.hd_demo_sk) OVER (PARTITION BY c.c_current_cdemo_sk) AS demo_count
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
),
last_sales AS (
    SELECT ws.ws_bill_customer_sk, MAX(ws.ws_sold_date_sk) AS last_sale_date
    FROM web_sales ws
    GROUP BY ws.ws_bill_customer_sk
),
sales_summary AS (
    SELECT cs.cs_bill_customer_sk, SUM(cs.cs_net_profit) AS total_profit, 
           SUM(cs.cs_quantity) AS total_quantity,
           RANK() OVER (ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN last_sales ls ON cs.cs_bill_customer_sk = ls.ws_bill_customer_sk
    WHERE cs.cs_sold_date_sk >= (SELECT MIN(d.d_date_sk)
                                  FROM date_dim d
                                  WHERE d.d_date BETWEEN '2022-01-01' AND '2023-01-01')
    GROUP BY cs.cs_bill_customer_sk
)
SELECT cd.c_customer_id, cd.cd_gender, cd.cd_marital_status, ss.total_profit, ss.total_quantity,
       CASE 
           WHEN ss.total_profit IS NULL THEN 'No Sales Yet'
           WHEN ss.total_quantity > 100 THEN 'High Spender'
           ELSE 'Low Activity'
       END AS customer_status,
       (SELECT SUM(ws.ws_ext_tax) FROM web_sales ws 
        WHERE ws.ws_bill_customer_sk = cd.c_customer_sk 
        AND ws.ws_sold_date_sk BETWEEN '2022-01-01' AND '2023-01-01'
        GROUP BY ws.ws_bill_customer_sk) AS total_tax_collected,
       COALESCE(MAX(ss.profit_rank), 0) AS rank,
       CASE 
           WHEN cd.demo_count = 0 THEN 'No Demographics Available'
           ELSE CONCAT('Demographics Count: ', cd.demo_count)
       END AS demographic_info
FROM customer_data cd
LEFT JOIN sales_summary ss ON cd.c_customer_sk = ss.cs_bill_customer_sk
WHERE cd.rn <= 10
AND cd.c_current_addr_sk IN (
    SELECT ca.ca_address_sk
    FROM customer_address ca
    WHERE ca.ca_city IS NOT NULL AND ca.ca_state = 'CA'
)
ORDER BY cd.cd_gender, ss.total_profit DESC;
