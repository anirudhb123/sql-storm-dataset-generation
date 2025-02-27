
WITH SalesData AS (
    SELECT 
        COALESCE(ws.web_site_sk, cs.cs_call_center_sk, ss.ss_store_sk) AS Sales_Channel,
        SUM(ws.ws_net_paid) AS Total_Web_Sales,
        SUM(cs.cs_net_paid) AS Total_Catalog_Sales,
        SUM(ss.ss_net_paid) AS Total_Store_Sales,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS Unique_Web_Orders,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS Unique_Catalog_Orders,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS Unique_Store_Orders
    FROM 
        web_sales ws
    FULL OUTER JOIN catalog_sales cs ON ws.ws_item_sk = cs.cs_item_sk
    FULL OUTER JOIN store_sales ss ON ws.ws_item_sk = ss.ss_item_sk
    WHERE 
        (ws.ws_sold_date_sk BETWEEN 2400 AND 2500 OR cs.cs_sold_date_sk BETWEEN 2400 AND 2500 OR ss.ss_sold_date_sk BETWEEN 2400 AND 2500)
    GROUP BY 
        Sales_Channel
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT CASE WHEN ws.ws_order_number IS NOT NULL THEN ws.ws_order_number END) AS Web_Order_Count,
        COUNT(DISTINCT CASE WHEN cs.cs_order_number IS NOT NULL THEN cs.cs_order_number END) AS Catalog_Order_Count,
        COUNT(DISTINCT CASE WHEN ss.ss_ticket_number IS NOT NULL THEN ss.ss_ticket_number END) AS Store_Order_Count,
        COALESCE(SUM(ws.ws_net_profit), 0) AS Total_Web_Profit,
        COALESCE(SUM(cs.cs_net_profit), 0) AS Total_Catalog_Profit,
        COALESCE(SUM(ss.ss_net_profit), 0) AS Total_Store_Profit
    FROM 
        customer c
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    GROUP BY 
        c.c_customer_sk
),
FinalStats AS (
    SELECT 
        cs.c_customer_sk,
        cs.Web_Order_Count,
        cs.Catalog_Order_Count,
        cs.Store_Order_Count,
        (cs.Total_Web_Profit + cs.Total_Catalog_Profit + cs.Total_Store_Profit) AS Total_Profit,
        ROW_NUMBER() OVER (ORDER BY (cs.Total_Web_Profit + cs.Total_Catalog_Profit + cs.Total_Store_Profit) DESC) AS Rank
    FROM 
        CustomerStats cs
)
SELECT 
    f.c_customer_sk,
    f.Web_Order_Count,
    f.Catalog_Order_Count,
    f.Store_Order_Count,
    f.Total_Profit,
    CASE 
        WHEN f.Rank <= 10 THEN 'Top Customers'
        ELSE 'Regular Customers'
    END AS Customer_Category
FROM 
    FinalStats f
WHERE 
    f.Total_Profit > 1000
ORDER BY 
    f.Total_Profit DESC;
