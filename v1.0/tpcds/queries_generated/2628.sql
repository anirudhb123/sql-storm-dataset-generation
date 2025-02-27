
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(ws.ws_net_paid) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
IncomeBandSales AS (
    SELECT 
        cd.cd_gender,
        COUNT(DISTINCT cs.c_customer_id) AS customer_count,
        AVG(cs.total_spent) AS avg_spent
    FROM 
        CustomerSales cs
    JOIN 
        customer_demographics cd ON cs.c_customer_id = cd.cd_demo_sk
    GROUP BY 
        cd.cd_gender
),
ItemSales AS (
    SELECT 
        i.i_item_id,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM 
        item i
    JOIN 
        web_sales ws ON i.i_item_sk = ws.ws_item_sk
    GROUP BY 
        i.i_item_id
)
SELECT 
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    COALESCE(COUNT(cb.customer_count), 0) AS customer_count,
    COALESCE(AVG(cb.avg_spent), 0) AS avg_spent,
    COALESCE(SUM(is.total_quantity_sold), 0) AS total_quantity_sold,
    COALESCE(SUM(is.total_net_profit), 0) AS total_net_profit
FROM 
    income_band ib
LEFT JOIN 
    IncomeBandSales cb ON cb.cd_gender = CASE 
                                             WHEN ib.ib_lower_bound < 30000 THEN 'M' 
                                             WHEN ib.ib_lower_bound >= 30000 THEN 'F' 
                                          END
LEFT JOIN 
    ItemSales is ON is.total_quantity_sold > 100
GROUP BY 
    ib.ib_income_band_sk, ib.ib_lower_bound, ib.ib_upper_bound
ORDER BY 
    ib.ib_income_band_sk;
