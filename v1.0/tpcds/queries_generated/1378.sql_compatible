
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_income_band_sk ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
IncomeBands AS (
    SELECT 
        ib.ib_income_band_sk,
        COUNT(cd.cd_demo_sk) AS customer_count
    FROM 
        customer_demographics cd
    LEFT JOIN income_band ib ON cd.cd_income_band_sk = ib.ib_income_band_sk
    GROUP BY 
        ib.ib_income_band_sk
),
TopPurchasedItems AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MIN(d_date_sk) FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
    HAVING 
        SUM(ws.ws_quantity) > 100
),
CustomerPurchases AS (
    SELECT 
        rc.c_customer_sk,
        SUM(ws.ws_sales_price) AS total_spent
    FROM 
        RankedCustomers rc
    JOIN web_sales ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        rc.c_customer_sk
),
EligibleCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(cp.total_spent, 0) AS total_spent,
        ib.ib_income_band_sk,
        ic.customer_count
    FROM 
        customer c
    JOIN IncomeBands ic ON c.c_current_cdemo_sk = ic.ib_income_band_sk
    LEFT JOIN CustomerPurchases cp ON c.c_customer_sk = cp.c_customer_sk
    WHERE 
        ic.customer_count > 50
)
SELECT 
    ec.c_customer_sk,
    ec.c_first_name,
    ec.c_last_name,
    ec.total_spent,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ir.promo_cost,
    ir.promo_name
FROM 
    EligibleCustomers ec
LEFT JOIN promotion ir ON ec.total_spent > ir.promo_cost
LEFT JOIN income_band ib ON ec.ib_income_band_sk = ib.ib_income_band_sk
WHERE 
    (ec.total_spent IS NULL OR ec.total_spent > 0)
ORDER BY 
    ec.total_spent DESC;
