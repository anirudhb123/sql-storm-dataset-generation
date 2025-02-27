
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_paid) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
CustomerSummary AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        hd.hd_income_band_sk,
        Q1.total_net_paid AS Q1_net_paid,
        Q2.total_net_paid AS Q2_net_paid
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN (
        SELECT 
            ws.bill_customer_sk,
            SUM(ws.net_paid) AS total_net_paid
        FROM 
            web_sales ws 
        WHERE 
            ws.sold_date_sk BETWEEN 2459759 AND 2459790
        GROUP BY 
            ws.bill_customer_sk
    ) Q1 ON Q1.bill_customer_sk = c.c_customer_sk
    LEFT JOIN (
        SELECT 
            ws.bill_customer_sk,
            SUM(ws.net_paid) AS total_net_paid
        FROM 
            web_sales ws 
        WHERE 
            ws.sold_date_sk BETWEEN 2459820 AND 2459850
        GROUP BY 
            ws.bill_customer_sk
    ) Q2 ON Q2.bill_customer_sk = c.c_customer_sk
),
HighSpendingCustomers AS (
    SELECT 
        c.*,
        RANK() OVER (ORDER BY c.Q1_net_paid + COALESCE(c.Q2_net_paid, 0) DESC) AS spending_rank
    FROM 
        CustomerSummary c
    WHERE 
        c.Q1_net_paid > (SELECT AVG(total_net_paid) FROM CustomerSummary) 
        OR (c.Q2_net_paid IS NOT NULL AND c.Q2_net_paid > (SELECT AVG(total_net_paid) FROM CustomerSummary))
)
SELECT 
    hs.c_first_name,
    hs.c_last_name,
    hs.cd_gender,
    hs.hd_income_band_sk,
    hs.spending_rank,
    R.total_quantity AS web_sales_quantity
FROM 
    HighSpendingCustomers hs
JOIN 
    RankedSales R ON hs.c_customer_sk = R.ws_item_sk
WHERE 
    R.rank = 1
ORDER BY 
    hs.spending_rank;
