
WITH RankedCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rnk
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate IS NOT NULL
),
CustomerOrders AS (
    SELECT 
        w.ws_bill_customer_sk,
        COUNT(DISTINCT w.ws_order_number) AS order_count,
        SUM(w.ws_net_profit) AS total_profit
    FROM 
        web_sales w
    GROUP BY 
        w.ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        rc.c_customer_sk,
        rc.c_customer_id,
        co.order_count,
        co.total_profit
    FROM 
        RankedCustomers rc
    LEFT JOIN 
        CustomerOrders co ON rc.c_customer_sk = co.ws_bill_customer_sk
    WHERE 
        rc.rnk <= 10
),
StoreSalesSummary AS (
    SELECT 
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid) AS total_sales,
        AVG(ss.ss_sales_price) AS average_price,
        COUNT(ss.ss_ticket_number) AS transaction_count
    FROM 
        store_sales ss
    WHERE 
        ss.ss_quantity > 0
    GROUP BY 
        ss.ss_sold_date_sk
),
ReturnDetails AS (
    SELECT 
        sr.returned_date_sk,
        SUM(sr.sr_return_amt) AS total_returns,
        COUNT(sr.sr_ticket_number) AS return_count
    FROM 
        store_returns sr
    GROUP BY 
        sr.returned_date_sk
)
SELECT 
    hvc.c_customer_id,
    hvc.order_count AS total_orders,
    hvc.total_profit,
    s.date,
    COALESCE(s.total_sales, 0) AS store_sales,
    COALESCE(r.total_returns, 0) AS total_returns,
    CASE 
        WHEN hvc.total_profit > COALESCE(s.total_sales, 0) THEN 'Profitable'
        ELSE 'Non-Profitable'
    END AS profitability_status
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    (SELECT DISTINCT d.d_date_sk AS date FROM date_dim d WHERE d.d_current_day = 'Y') AS d
LEFT JOIN 
    StoreSalesSummary s ON d.date = s.ss_sold_date_sk
LEFT JOIN 
    ReturnDetails r ON d.date = r.returned_date_sk
WHERE 
    (hvc.total_profit IS NOT NULL OR s.total_sales IS NOT NULL)
ORDER BY 
    hvc.total_profit DESC, hvc.c_customer_id;
