
WITH RankedSales AS (
    SELECT 
        ws.ws_item_sk,
        ws.ws_order_number,
        ws.ws_sales_price,
        ws.ws_net_profit,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_item_sk ORDER BY ws.ws_net_profit DESC) AS rn,
        COALESCE(NULLIF(ws.ws_sales_price, 0), NULL) AS adjusted_price
    FROM 
        web_sales ws
    LEFT JOIN 
        customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE 
        c.c_birth_year IS NOT NULL 
        AND (c.c_birth_month BETWEEN 1 AND 12)
        AND c.c_first_name IS NOT NULL
),
TotalSales AS (
    SELECT 
        rs.ws_item_sk,
        SUM(rs.ws_net_profit) AS total_net_profit,
        COUNT(rs.ws_order_number) AS order_count
    FROM 
        RankedSales rs
    WHERE 
        rs.rn <= 5
    GROUP BY 
        rs.ws_item_sk
),
FavoredItems AS (
    SELECT 
        ts.ws_item_sk,
        ts.total_net_profit,
        ts.order_count,
        (CASE WHEN ts.order_count > 5 THEN 'High Demand' ELSE 'Low Demand' END) AS demand_category
    FROM 
        TotalSales ts
)
SELECT 
    fi.ws_item_sk,
    fi.total_net_profit,
    fi.order_count,
    fi.demand_category,
    COALESCE(sm.sm_type, 'Standard') AS ship_mode
FROM 
    FavoredItems fi
LEFT JOIN 
    ship_mode sm ON sm.sm_ship_mode_sk = (SELECT sm_ship_mode_sk FROM store_sales ss 
                                           WHERE ss.ss_item_sk = fi.ws_item_sk 
                                           ORDER BY ss.ss_net_profit DESC LIMIT 1)
WHERE 
    fi.demand_category = 'High Demand'
UNION ALL
SELECT 
    fi.ws_item_sk,
    0 AS total_net_profit,
    0 AS order_count,
    'No Sales' AS demand_category,
    'Standard' AS ship_mode
FROM 
    FavoredItems fi
WHERE 
    fi.order_count = 0
ORDER BY 
    fi.total_net_profit DESC NULLS LAST;
