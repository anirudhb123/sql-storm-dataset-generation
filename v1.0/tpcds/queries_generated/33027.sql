
WITH RECURSIVE Sales_CTE AS (
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
Top_Sales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        sc.total_quantity,
        sc.total_profit
    FROM 
        Sales_CTE sc
    JOIN 
        item ON sc.ws_item_sk = item.i_item_sk
    WHERE 
        sc.rank <= 10
), 
Address_Summary AS (
    SELECT 
        ca_state,
        COUNT(DISTINCT c_customer_id) AS customer_count,
        AVG(cd_purchase_estimate) AS avg_purchase_estimate
    FROM 
        customer_address ca
    JOIN 
        customer c ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN 
        customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    GROUP BY 
        ca_state
), 
Returns_Summary AS (
    SELECT 
        ws_item_sk,
        SUM(sr_return_quantity) AS total_returns, 
        SUM(sr_return_amt) AS total_return_amt
    FROM 
        store_returns sr
    GROUP BY 
        ws_item_sk
)
SELECT 
    ts.i_product_name,
    ts.total_quantity,
    ts.total_profit,
    asum.ca_state,
    asum.customer_count,
    asum.avg_purchase_estimate,
    COALESCE(rs.total_returns, 0) AS total_returns,
    COALESCE(rs.total_return_amt, 0) AS total_return_amt
FROM 
    Top_Sales ts
JOIN 
    Address_Summary asum ON asum.customer_count > 100
LEFT JOIN 
    Returns_Summary rs ON ts.ws_item_sk = rs.ws_item_sk
WHERE 
    ts.total_profit > 1000
ORDER BY 
    ts.total_profit DESC;
