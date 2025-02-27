
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.bill_customer_sk,
        ws.ws_sold_date_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        ROW_NUMBER() OVER (PARTITION BY ws.bill_customer_sk ORDER BY SUM(ws.ws_quantity) DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim dd ON ws.ws_sold_date_sk = dd.d_date_sk
    WHERE 
        dd.d_year BETWEEN 2021 AND 2023
    GROUP BY 
        ws.web_site_sk, ws.bill_customer_sk, ws.ws_sold_date_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        COUNT(DISTINCT p.p_promo_id) AS promo_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c 
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk 
    LEFT JOIN 
        promotion p ON ws.ws_promo_sk = p.p_promo_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.cd_gender,
        cs.promo_count,
        cs.avg_purchase_estimate,
        cs.total_spent,
        RANK() OVER (ORDER BY cs.total_spent DESC) AS spending_rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.total_spent IS NOT NULL
)
SELECT 
    t.spending_rank,
    t.c_customer_sk,
    t.c_first_name,
    t.c_last_name,
    t.cd_gender,
    COALESCE(t.total_spent, 0) AS total_spent,
    COALESCE(r.total_quantity, 0) AS total_web_sales_quantity
FROM 
    TopCustomers t
LEFT JOIN 
    RankedSales r ON t.c_customer_sk = r.bill_customer_sk AND r.rn = 1
WHERE 
    t.spending_rank <= 10
ORDER BY 
    t.spending_rank;
