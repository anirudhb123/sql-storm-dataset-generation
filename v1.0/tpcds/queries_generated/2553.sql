
WITH CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_quantity) AS total_returned_quantity,
        SUM(sr_return_amt_inc_tax) AS total_returned_amount,
        COUNT(DISTINCT sr_ticket_number) AS return_count
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
), 
CustomerDemographics AS (
    SELECT 
        cd_demo_sk,
        cd_gender,
        cd_marital_status,
        cd_income_band_sk
    FROM 
        customer_demographics
), 
SalesMetrics AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_quantity) AS total_sales_quantity,
        SUM(ws_net_paid) AS total_sales_amount
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk BETWEEN 1000 AND 2000
    GROUP BY 
        ws_bill_customer_sk
), 
Promotions AS (
    SELECT 
        p_item_sk,
        COUNT(DISTINCT p_promo_id) AS promo_count
    FROM 
        promotion
    GROUP BY 
        p_item_sk
)
SELECT 
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    cd.cd_marital_status,
    COALESCE(r.total_returned_quantity, 0) AS total_returned_quantity,
    COALESCE(r.total_returned_amount, 0) AS total_returned_amount,
    COALESCE(s.total_sales_quantity, 0) AS total_sales_quantity,
    COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
    p.promo_count
FROM 
    customer c
LEFT JOIN 
    CustomerDemographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
LEFT JOIN 
    SalesMetrics s ON c.c_customer_sk = s.ws_bill_customer_sk
LEFT JOIN 
    Promotions p ON s.total_sales_quantity > 0 AND EXISTS (
        SELECT 
            1 
        FROM 
            item i 
        WHERE 
            i.i_item_sk = p.p_item_sk AND 
            i.i_current_price < 50
    )
WHERE 
    c.c_birth_year IS NOT NULL
ORDER BY 
    total_sales_amount DESC, 
    total_returned_quantity ASC;
