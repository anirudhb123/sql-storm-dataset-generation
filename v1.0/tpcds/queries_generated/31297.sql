
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_sold_date_sk,
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_paid) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY ws_sold_date_sk DESC) AS rn
    FROM 
        web_sales
    GROUP BY 
        ws_sold_date_sk, ws_item_sk
),
customer_info AS (
    SELECT 
        c.c_customer_sk,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate
    FROM 
        customer c
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE 
        cd.cd_purchase_estimate > 500
),
popular_items AS (
    SELECT 
        ws_item_sk,
        COUNT(*) AS sales_count
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
    HAVING 
        COUNT(*) > 100
),
returns_info AS (
    SELECT 
        wr_item_sk,
        SUM(wr_return_quantity) AS total_returns,
        SUM(wr_net_loss) AS total_loss
    FROM 
        web_returns
    GROUP BY 
        wr_item_sk
),
final_summary AS (
    SELECT 
        si.ws_item_sk,
        ss.total_quantity,
        ss.total_sales,
        COALESCE(ri.total_returns, 0) AS total_returns,
        COALESCE(ri.total_loss, 0) AS total_loss,
        CASE 
            WHEN ss.total_sales > 0 THEN (COALESCE(ri.total_losses, 0) / ss.total_sales) * 100
            ELSE NULL 
        END AS return_ratio
    FROM 
        sales_summary ss
    JOIN 
        popular_items pi ON ss.ws_item_sk = pi.ws_item_sk
    LEFT JOIN 
        returns_info ri ON ss.ws_item_sk = ri.wr_item_sk
)
SELECT 
    fi.ws_item_sk,
    fi.total_quantity,
    fi.total_sales,
    fi.total_returns,
    fi.total_loss,
    fi.return_ratio,
    ci.cd_gender,
    ci.cd_marital_status
FROM 
    final_summary fi
JOIN 
    customer_info ci ON ci.c_customer_sk IN (
        SELECT c_customer_sk FROM store_sales WHERE ss_item_sk = fi.ws_item_sk
    )
ORDER BY 
    fi.total_sales DESC
LIMIT 50;
