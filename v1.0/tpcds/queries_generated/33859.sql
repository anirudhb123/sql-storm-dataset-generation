
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws.item_sk,
        SUM(ws.ext_sales_price) AS Total_Sales,
        COUNT(ws.order_number) AS Total_Orders,
        ROW_NUMBER() OVER (PARTITION BY ws.item_sk ORDER BY SUM(ws.ext_sales_price) DESC) AS Rank
    FROM 
        web_sales ws
    WHERE 
        ws.sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws.item_sk
),
CustomerStats AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws.ws_order_number) AS Total_Web_Orders,
        AVG(ws.ws_net_paid) AS Avg_Net_Paid,
        pd.promo_name
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        promotion pd ON ws.ws_promo_sk = pd.p_promo_sk
    GROUP BY 
        c.c_customer_sk, pd.promo_name
),
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.Total_Web_Orders,
        cs.Avg_Net_Paid,
        RANK() OVER (ORDER BY cs.Avg_Net_Paid DESC) AS Customer_Rank
    FROM 
        CustomerStats cs
    WHERE 
        cs.Total_Web_Orders > 5
),
AddressInfo AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        COUNT(DISTINCT c.c_customer_sk) AS Customer_Count
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_address_sk, ca.ca_city, ca.ca_state
)
SELECT 
    a.ca_city,
    a.ca_state,
    COALESCE(tc.Customer_Rank, 0) AS Top_Customer_Rank,
    a.Customer_Count,
    SUM(cs.Total_Orders) AS Total_Web_Orders,
    SUM(cs.Total_Sales) AS Total_Sales 
FROM 
    AddressInfo a
LEFT JOIN 
    TopCustomers tc ON tc.c_customer_sk = a.Customer_Count
LEFT JOIN 
    SalesCTE cs ON a.Customer_Count = cs.item_sk
GROUP BY 
    a.ca_city, a.ca_state, tc.Customer_Rank
ORDER BY 
    Total_Sales DESC NULLS LAST;
