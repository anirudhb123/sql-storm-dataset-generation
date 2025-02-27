
WITH RECURSIVE SalesCTE AS (
    SELECT 
        s.ss_sold_date_sk,
        s.ss_item_sk,
        SUM(s.ss_quantity) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY s.ss_item_sk ORDER BY SUM(s.ss_quantity) DESC) AS rank_sales
    FROM
        store_sales s
    WHERE 
        s.ss_sold_date_sk >= (SELECT MAX(d.d_date_sk) - 30 FROM date_dim d) 
    GROUP BY 
        s.ss_sold_date_sk, s.ss_item_sk
), 
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
),
IncomeInsights AS (
    SELECT 
        h.hd_income_band_sk,
        COUNT(*) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        household_demographics h
    JOIN 
        customer_demographics cd ON h.hd_demo_sk = cd.cd_demo_sk
    GROUP BY 
        h.hd_income_band_sk
),
ReturnDetails AS (
    SELECT 
        sr_item_sk,
        COUNT(sr_returned_date_sk) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
)
SELECT 
    c.c_first_name,
    c.c_last_name,
    cs.total_spent,
    COALESCE(ri.total_returns, 0) AS total_returns,
    COALESCE(ri.total_return_amount, 0) AS total_return_amount,
    i.avg_purchase_estimate,
    d.d_date_id
FROM 
    CustomerSales cs
JOIN 
    customer c ON cs.c_customer_sk = c.c_customer_sk
LEFT JOIN 
    ReturnDetails ri ON cs.total_spent > 1000 AND cs.total_spent > (SELECT AVG(total_spent) FROM CustomerSales)
LEFT JOIN 
    IncomeInsights i ON (i.customer_count > 100) 
JOIN 
    date_dim d ON d.d_date_sk = (SELECT MAX(d_date_sk) FROM date_dim WHERE d_current_month = 'Y')
WHERE 
    (c.c_birth_country IS NOT NULL OR c.c_birth_country <> '')
ORDER BY 
    total_spent DESC, c.c_last_name, c.c_first_name;
