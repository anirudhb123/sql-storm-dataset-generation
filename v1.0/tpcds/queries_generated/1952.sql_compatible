
WITH SalesData AS (
    SELECT 
        ws.ws_item_sk,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_net_paid) AS total_net_paid,
        DENSE_RANK() OVER (PARTITION BY ws.ws_item_sk ORDER BY SUM(ws.ws_net_paid) DESC) AS sales_rank
    FROM 
        web_sales ws
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        ws.ws_item_sk
),
TopItems AS (
    SELECT 
        sd.ws_item_sk,
        sd.total_quantity,
        sd.total_net_paid
    FROM 
        SalesData sd
    WHERE 
        sd.sales_rank <= 5
),
CustomerSummary AS (
    SELECT 
        c.c_customer_id,
        SUM(ws.ws_net_paid_inc_tax) AS total_spent,
        COUNT(DISTINCT ws.ws_order_number) AS total_orders
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    WHERE 
        ws.ws_sold_date_sk BETWEEN (SELECT MAX(d_date_sk) - 30 FROM date_dim) AND (SELECT MAX(d_date_sk) FROM date_dim)
    GROUP BY 
        c.c_customer_id
),
FinalSummary AS (
    SELECT 
        ti.ws_item_sk,
        ti.total_quantity,
        ti.total_net_paid,
        cs.total_spent,
        cs.total_orders
    FROM 
        TopItems ti
    LEFT JOIN 
        CustomerSummary cs ON ti.ws_item_sk = (SELECT ws.ws_item_sk FROM web_sales ws WHERE ws.ws_bill_customer_sk = cs.c_customer_id LIMIT 1)
)
SELECT 
    fi.ws_item_sk,
    fi.total_quantity,
    fi.total_net_paid,
    COALESCE(fi.total_spent, 0) AS total_spent,
    COALESCE(fi.total_orders, 0) AS total_orders,
    CASE 
        WHEN fi.total_net_paid > 1000 THEN 'High Revenue'
        WHEN fi.total_net_paid > 500 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    FinalSummary fi
ORDER BY 
    fi.total_net_paid DESC;
