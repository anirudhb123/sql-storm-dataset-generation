
WITH RecursiveCTE AS (
    SELECT 
        c.c_customer_sk,
        c.c_current_addr_sk,
        ca.ca_state,
        ROW_NUMBER() OVER(PARTITION BY c.c_customer_sk ORDER BY c.c_birth_year, c.c_birth_month, c.c_birth_day) AS rnk
    FROM 
        customer c
    JOIN 
        customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    WHERE 
        ca.ca_state IS NOT NULL
        AND c.c_birth_year IS NOT NULL
),
RankedSales AS (
    SELECT 
        ws.ws_bill_customer_sk,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(DISTINCT ws.ws_order_number) AS order_count,
        AVG(ws.ws_net_paid) AS avg_net_paid
    FROM 
        web_sales ws
    WHERE 
        ws.ws_bill_customer_sk IN (SELECT c_customer_sk FROM customer WHERE c_current_addr_sk IS NOT NULL)
    GROUP BY 
        ws.ws_bill_customer_sk
),
NullHandling AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(rs.total_profit, 0) AS total_profit,
        COALESCE(rs.order_count, 0) AS order_count,
        COALESCE(rs.avg_net_paid, 0.00) AS avg_net_paid
    FROM 
        RecursiveCTE c
    LEFT JOIN 
        RankedSales rs ON c.c_customer_sk = rs.ws_bill_customer_sk
    WHERE 
        c.ca_state IN ('CA', 'NY')
),
FinalResults AS (
    SELECT 
        nh.c_customer_sk,
        nh.total_profit,
        nh.order_count,
        ROW_NUMBER() OVER(ORDER BY nh.total_profit DESC) AS rank
    FROM 
        NullHandling nh
    WHERE 
        nh.total_profit > (SELECT AVG(total_profit) FROM NullHandling)
        OR nh.order_count > (SELECT AVG(order_count) FROM NullHandling)
)
SELECT 
    fr.c_customer_sk,
    fr.total_profit,
    fr.order_count,
    CASE 
        WHEN fr.rank <= 5 THEN 'Top Performer'
        ELSE 'Regular Customer'
    END AS customer_segment,
    SUBSTR(CAST(fr.c_customer_sk AS VARCHAR), 1, 5) || '...' AS short_id
FROM 
    FinalResults fr
WHERE 
    EXISTS (
        SELECT 1
        FROM customer_demographics cd
        WHERE cd.cd_demo_sk = (SELECT c_current_cdemo_sk FROM customer WHERE c_customer_sk = fr.c_customer_sk)
        AND cd.cd_marital_status = 'M'
    )
ORDER BY 
    fr.total_profit DESC, fr.order_count ASC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY;
