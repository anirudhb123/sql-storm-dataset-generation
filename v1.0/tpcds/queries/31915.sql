
WITH RECURSIVE CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_sold_date_sk
    
    UNION ALL
    
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ws.ws_sold_date_sk,
        SUM(ws.ws_net_paid) AS total_sales
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    JOIN 
        CustomerSales cs ON cs.c_customer_sk = c.c_customer_sk
    WHERE 
        cs.ws_sold_date_sk < ws.ws_sold_date_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name, ws.ws_sold_date_sk
),
SalesSummary AS (
    SELECT 
        c.c_customer_sk, 
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        COUNT(ws.ws_item_sk) AS total_items_sold,
        SUM(ws.ws_net_paid) AS total_revenue
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_ship_customer_sk
    GROUP BY 
        c.c_customer_sk
),
IncomeCategory AS (
    SELECT 
        d.hd_demo_sk,
        CASE 
            WHEN ib.ib_lower_bound IS NULL THEN 'Unknown'
            ELSE CONCAT('$', CAST(ib.ib_lower_bound AS VARCHAR), ' - $', CAST(ib.ib_upper_bound AS VARCHAR))
        END AS income_bracket
    FROM 
        household_demographics d
    LEFT JOIN 
        income_band ib ON d.hd_income_band_sk = ib.ib_income_band_sk
),
FinalStats AS (
    SELECT 
        c.c_customer_sk,
        CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
        ss.total_orders,
        ss.total_items_sold,
        ss.total_revenue,
        ic.income_bracket
    FROM 
        SalesSummary ss
    JOIN 
        customer c ON ss.c_customer_sk = c.c_customer_sk
    LEFT JOIN 
        IncomeCategory ic ON c.c_current_hdemo_sk = ic.hd_demo_sk
)

SELECT 
    f.full_name,
    f.total_orders,
    f.total_items_sold,
    f.total_revenue,
    f.income_bracket,
    ROW_NUMBER() OVER (PARTITION BY f.income_bracket ORDER BY f.total_revenue DESC) AS revenue_rank
FROM 
    FinalStats f
WHERE 
    f.total_revenue IS NOT NULL
ORDER BY 
    f.income_bracket, revenue_rank
LIMIT 100;
