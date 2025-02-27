
WITH CustomerReturns AS (
    SELECT 
        sr.returned_date_sk,
        sr.return_time_sk,
        sr.return_item_sk,
        sr.return_customer_sk,
        sr.return_quantity,
        sr.return_amt,
        sr.return_tax,
        cs[*].net_profit AS net_profit,
        wr.returned_date_sk AS web_return_date
    FROM 
        store_returns sr
    LEFT JOIN 
        web_returns wr ON sr.return_item_sk = wr.return_item_sk 
                         AND sr.return_ticket_number = wr.return_order_number
    LEFT JOIN 
        store_sales ss ON sr.return_item_sk = ss.ss_item_sk
),
SalesAndDemographics AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT cs.cs_order_number) AS total_catalog_orders
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        catalog_sales cs ON c.c_customer_sk = cs.cs_ship_customer_sk
    WHERE 
        cd.cd_purchase_estimate > 500 AND cd.cd_credit_rating IS NOT NULL
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),
PromotionalReturns AS (
    SELECT 
        cr.return_item_sk,
        SUM(cr.return_quantity) AS total_returns_qty,
        SUM(cr.return_amnt) AS total_returns_amt,
        p.p_discount_active
    FROM 
        catalog_returns cr
    JOIN 
        promotion p ON cr.cr_promo_sk = p.p_promo_sk
    WHERE 
        cr.return_quantity > 0
    GROUP BY 
        cr.return_item_sk, p.p_discount_active
)
SELECT 
    cs.c_first_name,
    cs.c_last_name,
    cs.total_web_profit,
    cs.total_catalog_orders,
    COALESCE(pr.total_returns_qty, 0) AS total_returns_quantity,
    COALESCE(pr.total_returns_amt, 0) AS total_returns_amount,
    COUNT(DISTINCT CASE WHEN pr.p_discount_active = 'Y' THEN pr.return_item_sk END) AS promo_item_count
FROM 
    SalesAndDemographics cs
LEFT JOIN 
    PromotionalReturns pr ON cs.c_customer_sk = pr.return_item_sk
GROUP BY 
    cs.c_first_name, cs.c_last_name, cs.total_web_profit, cs.total_catalog_orders;
