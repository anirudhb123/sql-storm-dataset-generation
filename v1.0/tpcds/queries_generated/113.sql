
WITH TopCustomers AS (
    SELECT c.c_customer_sk, 
           c.c_customer_id, 
           SUM(ws.ws_net_paid) AS total_spent,
           ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid) DESC) AS rnk
    FROM customer c
    JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
    HAVING SUM(ws.ws_net_paid) > 1000
),
HighValueItems AS (
    SELECT i.i_item_sk, 
           i.i_item_id, 
           AVG(ws.ws_net_paid) AS avg_net_paid
    FROM item i
    JOIN web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
    HAVING AVG(ws.ws_net_paid) > (SELECT AVG(ws_net_paid) FROM web_sales)
),
CustomerDemographics AS (
    SELECT cd.cd_gender,
           cd.cd_marital_status,
           COUNT(*) AS demographic_count 
    FROM customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE c.c_birth_year BETWEEN 1970 AND 1990
    GROUP BY cd.cd_gender, 
             cd.cd_marital_status
)

SELECT tc.c_customer_id,
       tc.total_spent,
       hi.i_item_id,
       hi.avg_net_paid,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.demographic_count
FROM TopCustomers tc
LEFT JOIN HighValueItems hi ON tc.total_spent > 2000
JOIN CustomerDemographics cd ON cd.demographic_count > 10
WHERE tc.rnk <= 100
UNION ALL
SELECT NULL,
       NULL,
       hi.i_item_id,
       hi.avg_net_paid,
       cd.cd_gender,
       cd.cd_marital_status,
       cd.demographic_count 
FROM HighValueItems hi
CROSS JOIN CustomerDemographics cd
WHERE cd.cd_gender = 'M'
ORDER BY total_spent DESC, avg_net_paid DESC;
