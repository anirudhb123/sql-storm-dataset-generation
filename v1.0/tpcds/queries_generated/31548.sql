
WITH RECURSIVE sales_summary AS (
    SELECT 
        ws_ship_date_sk,
        ws_item_sk,
        SUM(ws_sales_price) AS total_sales,
        COUNT(ws_order_number) AS total_orders,
        RANK() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_sales_price) DESC) AS sales_rank
    FROM 
        web_sales
    GROUP BY 
        ws_ship_date_sk, ws_item_sk
), 
item_summary AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        i_current_price,
        COALESCE((
            SELECT ib_income_band_sk
            FROM household_demographics
            WHERE hd_demo_sk = (
                SELECT cd_demo_sk
                FROM customer
                WHERE c_current_hdemo_sk IS NOT NULL
                LIMIT 1
            )
        ), 0) AS income_band,
        AVG(total_sales) AS avg_sales,
        SUM(total_orders) AS order_count
    FROM 
        item
    LEFT JOIN sales_summary ON item.i_item_sk = sales_summary.ws_item_sk
    GROUP BY 
        i_item_sk, i_product_name, i_brand, i_current_price
),
top_items AS (
    SELECT 
        i_item_sk,
        i_product_name,
        i_brand,
        avg_sales,
        order_count
    FROM 
        item_summary
    WHERE 
        order_count > 5 AND 
        avg_sales > 50 
),
filtered_items AS (
    SELECT
        ti.i_item_sk,
        ti.i_product_name,
        ti.i_brand,
        ti.avg_sales,
        ti.order_count,
        ROW_NUMBER() OVER (ORDER BY ti.avg_sales DESC) AS rn
    FROM 
        top_items ti
)
SELECT 
    fi.i_item_sk,
    fi.i_product_name,
    fi.i_brand,
    fi.avg_sales,
    fi.order_count,
    COALESCE(ca.ca_city, 'Unknown') AS city,
    CASE 
        WHEN fi.avg_sales IS NULL THEN 'No Sales'
        ELSE 'Sales Exist'
    END AS sales_status
FROM 
    filtered_items fi
LEFT JOIN 
    customer c ON fi.order_count = c.c_customer_sk
LEFT JOIN 
    customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
WHERE 
    fi.rn <= 10
ORDER BY 
    fi.avg_sales DESC;
