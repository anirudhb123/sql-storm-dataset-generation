WITH CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY SUM(ws.ws_net_profit) DESC) AS gender_rank
    FROM 
        customer AS c
    JOIN 
        customer_demographics AS cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        web_sales AS ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        (c.c_birth_month = EXTRACT(MONTH FROM cast('2002-10-01' as date)) OR c.c_birth_day = EXTRACT(DAY FROM cast('2002-10-01' as date)))
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status
),

HighProfitCustomers AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        cs.total_quantity,
        cs.total_profit
    FROM 
        CustomerStats AS cs
    JOIN 
        customer AS c ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.total_profit > (SELECT AVG(total_profit) FROM CustomerStats)
)

SELECT 
    COALESCE(sp.s_store_name, 'Online') AS sales_channel,
    SUM(hpc.total_profit) AS total_sales_profit,
    COUNT(hpc.c_customer_sk) AS total_customers,
    SUM(CASE WHEN hpc.total_quantity > 5 THEN hpc.total_quantity ELSE 0 END) AS bulk_orders,
    STRING_AGG(DISTINCT CONCAT(hpc.c_first_name, ' ', hpc.c_last_name) || ' (Profit: ' || hpc.total_profit || ')', '; ') AS high_profit_customers
FROM 
    HighProfitCustomers AS hpc
LEFT JOIN 
    store AS sp ON hpc.c_customer_sk = sp.s_store_sk
FULL OUTER JOIN 
    (SELECT * FROM customer WHERE c_current_addr_sk IS NULL) AS poorly_addressed 
ON 
    hpc.c_customer_sk = poorly_addressed.c_customer_sk
WHERE 
    hpc.total_profit > 100
GROUP BY 
    sales_channel
HAVING 
    SUM(hpc.total_quantity) IS NOT NULL
ORDER BY 
    total_sales_profit DESC, sales_channel NULLS LAST;