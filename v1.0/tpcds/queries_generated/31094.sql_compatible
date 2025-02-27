
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_sales_price) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_order_number DESC) AS rn
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk >= (SELECT MAX(d_date_sk) FROM date_dim WHERE d_year = 2023)
    GROUP BY 
        ws_item_sk, ws_order_number
), 
CustomerSales AS (
    SELECT 
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(SUM(ws.net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk, c.c_first_name, c.c_last_name
), 
TopCustomers AS (
    SELECT 
        cs.c_customer_sk,
        cs.c_first_name,
        cs.c_last_name,
        cs.total_net_profit,
        cs.total_orders,
        DENSE_RANK() OVER (ORDER BY cs.total_net_profit DESC) AS rank
    FROM 
        CustomerSales cs
    WHERE 
        cs.total_net_profit > (
            SELECT 
                AVG(total_net_profit)
            FROM 
                CustomerSales
        )
), 
AddressCTE AS (
    SELECT 
        ca.ca_address_sk,
        ca.ca_city,
        ca.ca_state,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY ca.ca_city) AS city_rank
    FROM 
        customer_address ca
    WHERE 
        ca.ca_country = 'USA'
)
SELECT 
    tc.c_first_name,
    tc.c_last_name,
    tc.total_net_profit,
    aa.ca_city,
    aa.ca_state,
    aa.city_rank
FROM 
    TopCustomers tc
LEFT JOIN 
    AddressCTE aa ON tc.c_customer_sk = (SELECT c.c_current_addr_sk FROM customer c WHERE c.c_customer_sk = tc.c_customer_sk)
WHERE 
    tc.rank <= 10
ORDER BY 
    tc.total_net_profit DESC, aa.ca_state, aa.city_rank;
