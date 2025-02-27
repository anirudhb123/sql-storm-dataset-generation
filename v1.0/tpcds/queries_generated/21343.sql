
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_net_paid,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_paid DESC) as rnk
    FROM 
        web_sales ws
    WHERE 
        ws.ws_net_paid > 0
), 
CustomerCounts AS (
    SELECT 
        ca.ca_city,
        COUNT(DISTINCT c.c_customer_sk) AS customer_count
    FROM 
        customer_address ca
        LEFT JOIN customer c ON ca.ca_address_sk = c.c_current_addr_sk
    GROUP BY 
        ca.ca_city
), 
Demographics AS (
    SELECT 
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(cd.cd_dep_count, 0) AS dependency_count
    FROM 
        customer_demographics cd
    WHERE 
        cd.cd_gender IN ('M', 'F')
), 
SalesSummary AS (
    SELECT 
        COALESCE(SUM(ws.ws_net_profit), 0) AS total_profit,
        AVG(ws.ws_net_paid) AS avg_net_paid,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_count
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk IN (
            SELECT DISTINCT d.d_date_sk 
            FROM date_dim d 
            WHERE d.d_year = 2022 AND d.d_dow IN (1, 2, 3, 4, 5)
        )
)
SELECT 
    cc.ca_city,
    cc.customer_count,
    ds.cd_gender,
    ds.cd_marital_status,
    ss.total_profit,
    ss.avg_net_paid,
    ss.total_quantity,
    ss.order_count,
    r.ws_item_sk,
    r.ws_order_number,
    r.ws_net_paid
FROM 
    CustomerCounts cc
    LEFT JOIN Demographics ds ON ds.dependency_count > 1
    FULL OUTER JOIN SalesSummary ss ON cc.customer_count > 0
    LEFT JOIN RankedSales r ON r.rnk = 1 AND r.ws_net_paid = (SELECT MAX(ws2.ws_net_paid) FROM RankedSales ws2)
WHERE 
    cc.customer_count IS NOT NULL OR ds.cd_gender IS NOT NULL OR ss.total_profit > 0
ORDER BY 
    cc.customer_count DESC, 
    ss.total_profit DESC, 
    r.ws_net_paid ASC;
