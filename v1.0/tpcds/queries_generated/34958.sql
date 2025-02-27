
WITH RECURSIVE SalesCTE AS (
    SELECT 
        ws_item_sk,
        ws_order_number,
        ws_sales_price,
        ws_quantity,
        ws_ext_sales_price,
        ws_ext_discount_amt,
        ws_net_profit,
        1 AS Level
    FROM 
        web_sales
    WHERE 
        ws_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim)
        
    UNION ALL

    SELECT 
        cs_item_sk,
        cs_order_number,
        cs_sales_price,
        cs_quantity,
        cs_ext_sales_price,
        cs_ext_discount_amt,
        cs_net_profit,
        Level + 1
    FROM 
        catalog_sales
    WHERE 
        cs_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim)
        AND cs_item_sk IN (SELECT ws_item_sk FROM web_sales WHERE ws_sold_date_sk = (SELECT max(d_date_sk) FROM date_dim))
)

SELECT 
    sa.ws_item_sk,
    sa.ws_order_number,
    SUM(sa.ws_sales_price * sa.ws_quantity) AS Total_Sales_Amount,
    SUM(sa.ws_net_profit) AS Total_Profit,
    MAX(CASE 
            WHEN ca.ca_city IS NULL THEN 'Other'
            ELSE ca.ca_city
        END) AS City,
    ROW_NUMBER() OVER (PARTITION BY sa.ws_item_sk ORDER BY SUM(sa.ws_net_profit) DESC) AS Profit_Rank
FROM 
    web_sales sa
LEFT JOIN 
    customer_address ca ON sa.ws_bill_addr_sk = ca.ca_address_sk
JOIN 
    SalesCTE sc ON sa.ws_item_sk = sc.ws_item_sk
WHERE 
    sa.ws_net_paid > 0
GROUP BY 
    sa.ws_item_sk, sa.ws_order_number
HAVING 
    SUM(sa.ws_quantity) > 10 OR MAX(sc.Level) > 1
ORDER BY 
    Total_Sales_Amount DESC
LIMIT 100;
