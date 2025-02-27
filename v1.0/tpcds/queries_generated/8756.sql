
WITH CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        MAX(ws.ws_sales_price) AS max_purchase_price,
        AVG(ws.ws_net_paid) AS avg_order_value
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
),
StoreSales AS (
    SELECT 
        s.s_store_sk,
        SUM(ss.ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS total_store_sales,
        MAX(ss.ss_sales_price) AS max_store_price,
        AVG(ss.ss_net_paid) AS avg_store_transaction_value
    FROM 
        store s
    JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        COUNT(c.c_customer_sk) AS customer_count,
        AVG(cd.cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_demographics cd
    LEFT JOIN 
        customer c ON cd.cd_demo_sk = c.c_current_cdemo_sk
    GROUP BY 
        cd.cd_demo_sk
),
FinalReport AS (
    SELECT 
        cs.c_customer_sk,
        ss.s_store_sk,
        cs.total_net_profit,
        cs.total_orders,
        ss.total_store_profit,
        ss.total_store_sales,
        dd.customer_count,
        dd.avg_purchase_estimate
    FROM 
        CustomerSales cs
    JOIN 
        StoreSales ss ON cs.c_customer_sk % 10 = ss.s_store_sk % 10
    JOIN 
        Demographics dd ON cs.c_customer_sk % 100 = dd.cd_demo_sk % 100
)
SELECT 
    fr.c_customer_sk,
    fr.s_store_sk,
    fr.total_net_profit,
    fr.total_orders,
    fr.total_store_profit,
    fr.total_store_sales,
    fr.customer_count,
    fr.avg_purchase_estimate
FROM 
    FinalReport fr
WHERE 
    fr.total_net_profit > 1000
ORDER BY 
    fr.total_net_profit DESC;
