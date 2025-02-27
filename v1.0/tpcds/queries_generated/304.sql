
WITH RankedSales AS (
    SELECT 
        ws_item_sk,
        SUM(ws_quantity) AS total_quantity,
        SUM(ws_net_profit) AS total_profit,
        ROW_NUMBER() OVER (PARTITION BY ws_item_sk ORDER BY SUM(ws_net_profit) DESC) AS rank
    FROM 
        web_sales
    GROUP BY 
        ws_item_sk
),
PromotionSummary AS (
    SELECT 
        p.p_promo_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_ext_sales_price) AS total_sales
    FROM 
        promotion p
    JOIN 
        web_sales ws ON p.p_promo_sk = ws.ws_promo_sk
    GROUP BY 
        p.p_promo_sk
),
TopCustomers AS (
    SELECT 
        c.c_customer_sk,
        COUNT(DISTINCT ws_order_number) AS order_count,
        SUM(ws_net_profit) AS total_spent
    FROM 
        customer c
    JOIN 
        web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY 
        c.c_customer_sk
    HAVING 
        COUNT(DISTINCT ws_order_number) > 5
),
ItemReturnStats AS (
    SELECT 
        sr_item_sk,
        SUM(sr_return_quantity) AS total_returns,
        SUM(sr_return_amt) AS total_return_amount
    FROM 
        store_returns
    GROUP BY 
        sr_item_sk
),
FinalReport AS (
    SELECT 
        i.i_item_id,
        i.i_item_desc,
        COALESCE(SUM(rs.total_quantity), 0) AS total_web_sales_quantity,
        COALESCE(SUM(rs.total_profit), 0) AS total_web_sales_profit,
        COALESCE(ps.order_count, 0) AS promo_order_count,
        COALESCE(ps.total_sales, 0) AS promo_total_sales,
        COALESCE(cs.order_count, 0) AS customer_order_count,
        COALESCE(cs.total_spent, 0) AS customer_total_spent,
        COALESCE(rs.total_returns, 0) AS total_returns,
        COALESCE(rs.total_return_amount, 0) AS total_return_amount
    FROM 
        item i
    LEFT JOIN 
        RankedSales rs ON i.i_item_sk = rs.ws_item_sk
    LEFT JOIN 
        PromotionSummary ps ON i.i_item_sk = ps.p_promo_sk
    LEFT JOIN 
        TopCustomers cs ON i.i_item_sk = cs.c_customer_sk
    LEFT JOIN 
        ItemReturnStats rs ON i.i_item_sk = rs.sr_item_sk
    GROUP BY 
        i.i_item_id, i.i_item_desc
    HAVING 
        SUM(rs.total_quantity) > 100
        OR SUM(ps.total_sales) > 5000
    ORDER BY 
        total_web_sales_profit DESC
)
SELECT *
FROM FinalReport;
