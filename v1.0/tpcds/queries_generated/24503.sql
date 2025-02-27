
WITH CustomerInfo AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS rn
    FROM 
        customer c
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
),
AggregateSales AS (
    SELECT 
        ws_bill_customer_sk,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(ws_order_number) AS order_count
    FROM 
        web_sales
    GROUP BY 
        ws_bill_customer_sk
),
HighValueCustomers AS (
    SELECT 
        c.customer_id,
        ag.total_net_profit,
        ag.order_count,
        ADDRESS.ca_city,
        ADDRESS.ca_state,
        RANK() OVER (PARTITION BY c.c_current_addr_sk ORDER BY ag.total_net_profit DESC) AS rank_by_profit
    FROM 
        CustomerInfo c
    JOIN 
        AggregateSales ag ON c.c_customer_id = ag.ws_bill_customer_sk
    JOIN 
        customer_address ADDRESS ON c.c_current_addr_sk = ADDRESS.ca_address_sk
    WHERE 
        ag.total_net_profit IS NOT NULL
        AND ag.order_count >= (SELECT AVG(order_count) FROM AggregateSales)
),
SalesReturnSummary AS (
    SELECT 
        sr_returning_customer_sk,
        COUNT(sr_item_sk) AS total_returns,
        SUM(sr_return_amt) AS total_returned_amount
    FROM 
        store_returns
    GROUP BY 
        sr_returning_customer_sk
),
FinalReport AS (
    SELECT 
        hvc.customer_id,
        hvc.total_net_profit,
        hvc.order_count,
        srs.total_returns,
        srs.total_returned_amount,
        hvc.ca_city,
        hvc.ca_state,
        COALESCE(srs.total_returned_amount, 0) AS effective_returned_amount
    FROM 
        HighValueCustomers hvc
    LEFT JOIN 
        SalesReturnSummary srs ON hvc.c_customer_id = srs.sr_returning_customer_sk
)
SELECT 
    *,
    CASE 
        WHEN total_net_profit > 10000 THEN 'Gold'
        WHEN total_net_profit BETWEEN 5000 AND 10000 THEN 'Silver'
        ELSE 'Bronze'
    END AS customer_tier,
    ROUND((total_net_profit - effective_returned_amount) / NULLIF(total_net_profit, 0) * 100, 2) AS net_profit_margin
FROM 
    FinalReport
WHERE 
    effective_returned_amount IS NOT NULL
ORDER BY 
    total_net_profit DESC, effective_returned_amount ASC
LIMIT 100
OFFSET 10;
