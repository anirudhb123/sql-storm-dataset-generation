
WITH RankedSales AS (
    SELECT 
        ws.web_site_sk,
        ws.ws_order_number,
        ws.ws_quantity,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rn
    FROM 
        web_sales ws
    JOIN 
        date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE 
        d.d_year = 2022
        AND ws.ws_net_profit > (SELECT AVG(ws2.ws_net_profit) FROM web_sales ws2 WHERE ws2.ws_sold_date_sk = ws.ws_sold_date_sk)
),
TopWarehouse AS (
    SELECT 
        w.w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM 
        inventory i
    JOIN 
        warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    GROUP BY 
        w.w_warehouse_sk
    HAVING 
        SUM(i.inv_quantity_on_hand) > 1000
),
CustomerReturns AS (
    SELECT 
        sr_customer_sk,
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
    HAVING 
        SUM(sr_return_amt) > 100
)

SELECT 
    c.c_customer_id,
    d.d_date,
    COALESCE(r.total_return_amt, 0) AS total_return_amount,
    SUM(CASE WHEN rs.rn = 1 THEN rs.ws_net_profit ELSE 0 END) AS highest_net_profit
FROM 
    customer c 
LEFT JOIN 
    CustomerReturns r ON c.c_customer_sk = r.sr_customer_sk
JOIN 
    RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
JOIN 
    date_dim d ON rs.ws_order_number = d.d_date_sk
JOIN 
    TopWarehouse tw ON rs.web_site_sk = tw.w_warehouse_sk
WHERE 
    c.c_birth_year < 1990 
    AND (c.c_preferred_cust_flag = 'Y' OR r.total_return_amt IS NULL)
GROUP BY 
    c.c_customer_id, d.d_date, r.total_return_amt
ORDER BY 
    total_return_amount DESC, highest_net_profit DESC;
