
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rank_by_purchase
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
        AND (cd.cd_marital_status = 'M' OR cd.cd_marital_status IS NULL)
),
HighValueItems AS (
    SELECT 
        i.i_item_sk,
        i.i_item_id,
        i.i_current_price,
        CASE 
            WHEN i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2) 
            THEN 'High Value'
            ELSE 'Regular'
        END AS value_category
    FROM 
        item i
    WHERE 
        i.i_rec_start_date <= CURRENT_DATE
        AND (i.i_rec_end_date IS NULL OR i.i_rec_end_date > CURRENT_DATE)
),
CustomerReturns AS (
    SELECT 
        sr.sr_customer_sk,
        COALESCE(SUM(sr.sr_return_quantity), 0) AS total_returns,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_return_tickets,
        SUM(CASE WHEN sr.sr_return_qty > 10 THEN 1 ELSE 0 END) AS bulk_returns
    FROM 
        store_returns sr
    GROUP BY 
        sr.sr_customer_sk
)
SELECT 
    rc.c_customer_id,
    rc.cd_gender,
    rc.cd_marital_status,
    hvi.i_item_id,
    hvi.value_category,
    COALESCE(cr.total_returns, 0) AS total_returns,
    cr.distinct_return_tickets,
    cr.bulk_returns
FROM 
    RankedCustomers rc
JOIN 
    (
        SELECT 
            ws.ws_item_sk,
            ws.ws_order_number,
            ws.ws_sales_price,
            ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_sales_price DESC) AS top_sales
        FROM 
            web_sales ws
        WHERE 
            ws.ws_sold_date_sk >= (SELECT MAX(d.d_date_sk) FROM date_dim d WHERE d.d_date = CURRENT_DATE - INTERVAL '30' DAY)
    ) AS ws ON rc.c_customer_sk = ws.ws_bill_customer_sk
JOIN 
    HighValueItems hvi ON ws.ws_item_sk = hvi.i_item_sk
LEFT JOIN 
    CustomerReturns cr ON rc.c_customer_sk = cr.sr_customer_sk
WHERE 
    rc.rank_by_purchase = 1
    AND (hvi.value_category = 'High Value' OR hvi.value_category IS NULL)
ORDER BY 
    rc.cd_gender, cr.total_returns DESC;
