
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_net_paid,
        ws.ws_sold_date_sk,
        DENSE_RANK() OVER(PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_paid DESC) as sales_rank
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
),
TopWebsites AS (
    SELECT 
        web_site_sk,
        SUM(ws_net_paid) AS total_sales
    FROM 
        RankedSales
    WHERE 
        sales_rank <= 10
    GROUP BY 
        web_site_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        SUM(COALESCE(ws.ws_net_paid, 0)) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender
),
HighSpendingCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.cd_gender,
        cs.total_spent,
        ROW_NUMBER() OVER(PARTITION BY cs.cd_gender ORDER BY cs.total_spent DESC) AS gender_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent > (SELECT AVG(total_spent) FROM CustomerStats)
)
SELECT 
    web.web_site_id,
    COALESCE(SUM(hs.total_spent), 0) AS total_sales,
    COUNT(DISTINCT hsc.c_customer_sk) AS number_of_customers
FROM 
    TopWebsites tw
JOIN 
    web_site web ON tw.web_site_sk = web.web_site_sk
LEFT JOIN 
    HighSpendingCustomers hsc ON 
        hsc.total_spent > 1000 AND 
        hsc.c_customer_sk IN (SELECT ws_bill_customer_sk FROM web_sales WHERE ws_sold_date_sk BETWEEN 20220101 AND 20221231)
GROUP BY 
    web.web_site_id
ORDER BY 
    total_sales DESC
LIMIT 5;
