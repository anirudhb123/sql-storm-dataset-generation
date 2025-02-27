
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_ext_sales_price DESC) AS SalesRank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (SELECT d.d_date_sk 
                                FROM date_dim d 
                                WHERE d.d_year = 2023 
                                AND d.d_moy IN (1, 2, 3))
)
SELECT 
    ca.cat_address_id,
    COUNT(DISTINCT CASE 
        WHEN R.SalesRank = 1 THEN R.ws_order_number 
        ELSE NULL 
    END) AS HighValueOrders,
    SUM(COALESCE(R.ws_ext_sales_price, 0) * R.ws_quantity) AS TotalSales,
    MAX(i.i_current_price) AS MaxItemPrice
FROM 
    customer_address ca
LEFT JOIN 
    customer c ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN 
    RankedSales R ON R.ws_item_sk = i.i_item_sk
LEFT JOIN 
    item i ON i.i_item_sk = R.ws_item_sk
WHERE 
    c.c_birth_month IS NOT NULL 
    AND ca.ca_country = 'USA'
    AND (SELECT COUNT(*) FROM customer_demographics cd 
          WHERE cd.cd_demo_sk = c.c_current_cdemo_sk 
          AND cd.cd_marital_status = 'M') > 0
GROUP BY 
    ca.ca_address_id
HAVING 
    SUM(R.ws_quantity) > (SELECT AVG(ws_quantity) 
                          FROM web_sales 
                          WHERE ws_item_sk IN (SELECT DISTINCT ws_item_sk 
                                               FROM web_sales 
                                               WHERE ws_sold_date_sk = (SELECT MAX(ws_sold_date_sk) 
                                                                         FROM web_sales))) 
UNION ALL
SELECT 
    NULL AS ca_address_id,
    NULL AS HighValueOrders,
    SUM(ws.ws_net_paid) AS TotalSales,
    NULL AS MaxItemPrice
FROM 
    web_sales ws 
WHERE 
    ws.ws_bill_customer_sk IS NOT NULL
    AND (ws.ws_net_paid > 500 OR ws.ws_net_profit < -100)
    AND EXTRACT(MONTH FROM (SELECT d.d_date FROM date_dim d 
                             WHERE d.d_date_sk = ws.ws_sold_date_sk)) = 7
ORDER BY 
    TotalSales DESC;
