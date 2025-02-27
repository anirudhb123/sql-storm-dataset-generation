
WITH Customer_Sales AS (
    SELECT 
        c.c_customer_sk,
        c.c_last_name,
        c.c_first_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_profit) AS avg_net_profit
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_last_name, c.c_first_name
),
High_Value_Customers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_last_name,
        cs.c_first_name,
        cs.total_sales,
        cs.order_count,
        cs.avg_net_profit
    FROM 
        Customer_Sales cs
    WHERE 
        cs.total_sales > (SELECT AVG(total_sales) FROM Customer_Sales)
),
Top_Sellers AS (
    SELECT 
        ic.i_item_id,
        ic.i_item_desc,
        SUM(ws.ws_quantity) AS total_sold,
        SUM(ws.ws_ext_sales_price) AS total_revenue
    FROM 
        item ic
    JOIN 
        web_sales ws ON ic.i_item_sk = ws.ws_item_sk
    GROUP BY 
        ic.i_item_id, ic.i_item_desc
    ORDER BY 
        total_revenue DESC
    LIMIT 5
),
Store_Sales AS (
    SELECT 
        ss.s_store_sk,
        SUM(ss.ss_net_paid) AS store_total_sales,
        COUNT(ss.ss_ticket_number) AS store_order_count
    FROM 
        store_sales ss
    GROUP BY 
        ss.s_store_sk
)
SELECT 
    cvc.c_last_name,
    cvc.c_first_name,
    cvc.total_sales,
    cvc.order_count,
    cvc.avg_net_profit,
    ts.total_sold,
    ts.total_revenue,
    ss.store_total_sales,
    ss.store_order_count
FROM 
    High_Value_Customers cvc
LEFT JOIN 
    Top_Sellers ts ON ts.total_sold = (SELECT MAX(total_sold) FROM Top_Sellers)
JOIN 
    Store_Sales ss ON ss.store_order_count > 0
WHERE 
    cvc.total_sales IS NOT NULL 
ORDER BY 
    cvc.total_sales DESC;
