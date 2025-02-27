
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        COALESCE(STRING_AGG(DISTINCT CONCAT_WS(' ', c.c_first_name, c.c_last_name), ', ') 
                  FILTER (WHERE cs.ws_order_number IS NOT NULL), 'No Sales') AS sales_customers,
        COUNT(DISTINCT ws.ws_order_number) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit
    FROM 
        customer c
    LEFT JOIN
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status = 'M' AND cd.cd_gender = 'F'
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name
),
RankedSales AS (
    SELECT 
        c.*, 
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM 
        CustomerSales c
)
SELECT 
    r.c_customer_id,
    r.sales_customers,
    r.total_sales,
    r.total_profit,
    r.sales_rank
FROM 
    RankedSales r
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_profit DESC;
