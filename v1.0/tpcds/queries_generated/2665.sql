
WITH SalesSummary AS (
    SELECT 
        ws.web_site_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        AVG(ws.ws_net_paid) AS average_net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year = 2022
    GROUP BY 
        ws.web_site_sk
),
CustomerInfo AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_paid) AS total_spending
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, cd.cd_gender, cd.cd_marital_status
),
RankedCustomers AS (
    SELECT 
        ci.c_customer_sk,
        ci.cd_gender,
        ci.cd_marital_status,
        ci.total_spending,
        RANK() OVER (PARTITION BY ci.cd_gender ORDER BY ci.total_spending DESC) AS spending_rank
    FROM 
        CustomerInfo ci
)
SELECT 
    ss.web_site_sk,
    rc.cd_gender,
    rc.cd_marital_status,
    ss.total_quantity,
    ss.total_net_paid,
    ss.average_net_paid,
    rc.total_spending,
    rc.spending_rank
FROM 
    SalesSummary ss
JOIN 
    RankedCustomers rc ON ss.web_site_sk = 
        (SELECT ws.web_site_sk 
         FROM web_sales ws 
         WHERE ws.ws_bill_customer_sk IN (SELECT c.c_customer_sk FROM customer c)
         AND ws.ws_sold_date_sk = (SELECT d.d_date_sk FROM date_dim d WHERE d.d_year = 2022)
         GROUP BY ws.web_site_sk 
         ORDER BY SUM(ws.ws_net_paid) DESC 
         LIMIT 1)
WHERE 
    rc.spending_rank <= 10
ORDER BY 
    ss.total_net_paid DESC,
    rc.total_spending DESC;
