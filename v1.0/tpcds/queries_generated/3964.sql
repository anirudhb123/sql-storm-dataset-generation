
WITH CustomerSales AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(ws.ws_order_number) AS total_orders,
        COUNT(DISTINCT ws.ws_item_sk) AS unique_items_purchased
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        c.c_birth_year BETWEEN 1980 AND 1990 
        AND c.c_preferred_cust_flag = 'Y'
    GROUP BY 
        c.c_customer_id
),
TopCustomers AS (
    SELECT 
        c_customer_id,
        total_profit,
        total_orders,
        unique_items_purchased,
        RANK() OVER (ORDER BY total_profit DESC) AS rank
    FROM 
        CustomerSales
),
CustomerDetails AS (
    SELECT
        cc.cc_name AS call_center_name,
        cu.c_customer_id,
        cu.total_profit,
        cu.total_orders,
        cu.unique_items_purchased
    FROM 
        TopCustomers cu
    JOIN 
        call_center cc ON cc.cc_call_center_sk = (
            SELECT 
                MIN(ss.ss_store_sk) 
            FROM 
                store s 
            JOIN 
                store_sales ss ON s.s_store_sk = ss.ss_store_sk 
            JOIN 
                web_sales ws ON ws.ws_ship_customer_sk = cu.c_customer_id
            WHERE 
                ws.ws_sold_date_sk = (
                    SELECT 
                        MAX(ws_sold_date_sk) 
                    FROM 
                        web_sales 
                    WHERE 
                        ws_ship_customer_sk = cu.c_customer_id
                )
        )
)
SELECT 
    cd.call_center_name,
    COUNT(*) AS num_top_customers,
    AVG(cd.total_profit) AS avg_profit,
    SUM(cd.total_orders) AS total_orders,
    SUM(cd.unique_items_purchased) AS total_unique_items
FROM 
    CustomerDetails cd
WHERE 
    cd.total_profit > (
        SELECT 
            AVG(total_profit) 
        FROM 
            TopCustomers
    )
GROUP BY 
    cd.call_center_name
ORDER BY 
    num_top_customers DESC;
