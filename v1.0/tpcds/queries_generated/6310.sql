
WITH SalesData AS (
    SELECT 
        ws.web_site_id,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders,
        SUM(ws.ws_quantity) AS total_quantity,
        AVG(ws.ws_net_paid_inc_tax) AS avg_net_paid_inc_tax,
        d.d_year,
        d.d_month_seq,
        d.d_week_seq
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN 
        store s ON ws.ws_ship_addr_sk = s.s_store_sk
    WHERE 
        d.d_year = 2022
        AND cd.cd_gender = 'F'
        AND s.s_state IN ('CA', 'NY', 'TX')
    GROUP BY 
        ws.web_site_id, d.d_year, d.d_month_seq, d.d_week_seq
),
RankedSales AS (
    SELECT 
        web_site_id,
        total_net_profit,
        total_orders,
        total_quantity,
        avg_net_paid_inc_tax,
        DENSE_RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank
    FROM 
        SalesData
)
SELECT 
    web_site_id,
    total_net_profit,
    total_orders,
    total_quantity,
    avg_net_paid_inc_tax,
    profit_rank
FROM 
    RankedSales
WHERE 
    profit_rank <= 10
ORDER BY 
    profit_rank;
