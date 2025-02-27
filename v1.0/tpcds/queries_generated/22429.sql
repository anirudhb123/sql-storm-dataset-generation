
WITH ranked_sales AS (
    SELECT 
        ws.web_site_sk, 
        ws.ws_order_number, 
        ws.ws_sales_price, 
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.web_site_sk ORDER BY ws.ws_net_profit DESC) AS rank
    FROM 
        web_sales ws
    JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_marital_status IS NOT NULL
        AND cd.cd_gender IN ('M', 'F')
),
sales_summary AS (
    SELECT 
        rs.web_site_sk,
        SUM(rs.ws_sales_price) AS total_sales,
        AVG(rs.ws_net_profit) AS average_profit,
        COUNT(DISTINCT rs.ws_order_number) AS order_count
    FROM 
        ranked_sales rs
    WHERE 
        rs.rank <= 5
    GROUP BY 
        rs.web_site_sk
),
address_summary AS (
    SELECT 
        ca.ca_state, 
        COUNT(DISTINCT c.c_customer_sk) AS customer_count,
        MAX(c.c_birth_year) AS last_birth_year
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    WHERE 
        ca.ca_country = 'USA'
    GROUP BY 
        ca.ca_state
)
SELECT 
    ss.web_site_sk, 
    ss.total_sales, 
    ss.average_profit, 
    ss.order_count,
    asu.ca_state,
    asu.customer_count,
    COALESCE(asu.last_birth_year, 1900) AS last_birth_year,
    CASE 
        WHEN ss.average_profit > 100 THEN 'High Profit'
        WHEN ss.average_profit BETWEEN 50 AND 100 THEN 'Medium Profit'
        ELSE 'Low Profit'
    END AS profit_category
FROM 
    sales_summary ss
FULL OUTER JOIN 
    address_summary asu ON ss.web_site_sk = asu.customer_count
WHERE 
    ss.total_sales IS NOT NULL
    OR asu.customer_count > 0
ORDER BY 
    ss.total_sales DESC NULLS LAST;
