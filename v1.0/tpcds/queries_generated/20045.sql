
WITH RankedReturns AS (
    SELECT 
        sr_customer_sk, 
        COUNT(sr_ticket_number) AS return_count, 
        SUM(sr_return_quantity) AS total_returned_qty,
        ROW_NUMBER() OVER (PARTITION BY sr_customer_sk ORDER BY SUM(sr_return_quantity) DESC) AS rn
    FROM 
        store_returns
    GROUP BY 
        sr_customer_sk
),
TopReturners AS (
    SELECT 
        rr.sr_customer_sk,
        rr.return_count, 
        rr.total_returned_qty,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_income_band_sk,
        cd.cd_purchase_estimate
    FROM 
        RankedReturns rr
    JOIN 
        customer_demographics cd ON rr.sr_customer_sk = cd.cd_demo_sk
    WHERE 
        rr.rn = 1 
        AND cd.cd_purchase_estimate > (SELECT AVG(cd_purchase_estimate) FROM customer_demographics)
)
SELECT 
    ca_city, 
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS total_orders,
    COUNT(DISTINCT ws_ship_customer_sk) AS unique_customers,
    MAX(total_returned_qty) FILTER (WHERE total_returned_qty IS NOT NULL) AS max_returned_qty
FROM 
    web_sales ws
JOIN 
    TopReturners tr ON ws.ws_bill_customer_sk = tr.sr_customer_sk
JOIN 
    customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
WHERE 
    ca.ca_state = 'CA' 
    AND ws.ws_sales_price > (
        SELECT 
            AVG(ws_sales_price)
        FROM 
            web_sales
        WHERE 
            ws_ship_mode_sk IN (SELECT sm_ship_mode_sk FROM ship_mode WHERE sm_type = 'AIR')
    )
GROUP BY 
    ca_city 
HAVING 
    SUM(ws_ext_sales_price) > 10000 
ORDER BY 
    total_sales DESC;

WITH SalesData AS (
    SELECT 
        s.s_store_sk,
        COALESCE(SUM(ss_net_profit), 0) AS total_net_profit,
        COUNT(DISTINCT ss_ticket_number) AS total_tickets
    FROM 
        store s 
    LEFT JOIN 
        store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY 
        s.s_store_sk
),
RankedStores AS (
    SELECT 
        sd.s_store_sk,
        sd.total_net_profit,
        sd.total_tickets,
        ROW_NUMBER() OVER (ORDER BY sd.total_net_profit DESC) AS rank
    FROM 
        SalesData sd
)
SELECT 
    rs.s_store_sk,
    rs.total_net_profit,
    rs.total_tickets
FROM 
    RankedStores rs
WHERE 
    rs.rank <= (SELECT COUNT(*) / 10 FROM RankedStores)
```
