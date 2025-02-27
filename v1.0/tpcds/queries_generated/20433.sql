
WITH RankedSales AS (
    SELECT 
        ss_customer_sk,
        SUM(ss_net_profit) AS total_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss_customer_sk ORDER BY SUM(ss_net_profit) DESC) AS profit_rank
    FROM 
        store_sales
    GROUP BY 
        ss_customer_sk
),
CustomerDetails AS (
    SELECT 
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cd.cd_gender,
        cd.cd_marital_status,
        COALESCE(ca.ca_city, 'Unknown') AS city,
        SUM(CASE WHEN ws.ws_sales_price IS NOT NULL THEN ws.ws_net_paid ELSE 0 END) AS total_web_spending,
        COUNT(DISTINCT ws.ws_order_number) AS total_web_orders,
        SUM(COALESCE(ws.ws_ext_discount_amt, 0)) AS total_discount,
        COUNT(DISTINCT CASE WHEN wr.wr_item_sk IS NOT NULL THEN wr.wr_order_number END) AS total_web_returns
    FROM 
        customer c 
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN 
        web_returns wr ON ws.ws_order_number = wr.wr_order_number 
    WHERE 
        (cd.cd_marital_status = 'M' OR cd.cd_gender = 'F') 
        AND (ca.ca_city IS NOT NULL OR ca.ca_city <> 'Unknown')
    GROUP BY 
        c.c_customer_id, c.c_first_name, c.c_last_name, cd.cd_gender, cd.cd_marital_status, ca.ca_city
),
FinalResult AS (
    SELECT 
        c.c_customer_id,
        c.total_net_profit,
        cd.*
    FROM 
        RankedSales c
    JOIN 
        CustomerDetails cd ON c.ss_customer_sk = cd.c_customer_id
    WHERE 
        c.total_net_profit > (
            SELECT 
                AVG(total_net_profit) 
            FROM 
                RankedSales
            WHERE 
                profit_rank <= 10
        )
    ORDER BY 
        c.total_net_profit DESC
)
SELECT 
    *,
    CASE 
        WHEN total_web_orders >= 10 THEN 'Frequent Buyer'
        WHEN total_web_orders BETWEEN 5 AND 9 THEN 'Occasional Buyer'
        ELSE 'Rare Buyer'
    END AS buyer_category
FROM 
    FinalResult
WHERE 
    NOT EXISTS (
        SELECT 1 
        FROM store s 
        WHERE s.s_store_sk = (SELECT TOP 1 ss_store_sk FROM store_sales WHERE ss_ticket_number = 1)
    )
UNION ALL
SELECT 
    'No Data' AS c_customer_id,
    NULL AS total_net_profit,
    NULL AS city,
    'N/A' AS gender,
    'N/A' AS marital_status,
    0 AS total_web_spending,
    0 AS total_web_orders,
    0 AS total_discount,
    0 AS total_web_returns,
    'Unknown Buyer' AS buyer_category
WHERE 
    NOT EXISTS (SELECT 1 FROM FinalResult);
