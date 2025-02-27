
WITH RankedSales AS (
    SELECT 
        cs_item_sk,
        cs_order_number,
        RANK() OVER (PARTITION BY cs_item_sk ORDER BY cs_net_profit DESC) AS profit_rank,
        SUM(cs_net_profit) OVER (PARTITION BY cs_item_sk) AS total_profit,
        COUNT(*) OVER (PARTITION BY cs_item_sk) AS sales_count
    FROM catalog_sales
    WHERE cs_ship_mode_sk IS NOT NULL 
      AND cs_net_profit IS NOT NULL 
      AND cs_quantity > 0
),
HighProfitSales AS (
    SELECT 
        item.i_item_id,
        item.i_product_name,
        ranked.cs_order_number,
        ranked.profit_rank,
        ranked.total_profit,
        ranked.sales_count,
        COALESCE(returns.cr_return_quantity, 0) AS return_quantity,
        COALESCE(returns.cr_return_amount, 0) AS return_amount,
        CASE 
            WHEN COALESCE(returns.cr_return_quantity, 0) > 0 THEN 'Returned'
            ELSE 'Not Returned'
        END AS return_status
    FROM RankedSales ranked
    JOIN item ON ranked.cs_item_sk = item.i_item_sk
    LEFT JOIN catalog_returns returns ON ranked.cs_order_number = returns.cr_order_number 
        AND ranked.cs_item_sk = returns.cr_item_sk
    WHERE ranked.profit_rank <= 5
),
CustomerDemographics AS (
    SELECT 
        customer.c_customer_id,
        demographics.cd_gender,
        demographics.cd_marital_status,
        demographics.cd_purchase_estimate,
        demographics.cd_credit_rating,
        demographics.cd_dep_count,
        demographics.cd_dep_college_count
    FROM customer AS customer 
    LEFT JOIN customer_demographics AS demographics ON customer.c_current_cdemo_sk = demographics.cd_demo_sk
)
SELECT 
    sale.i_product_name,
    sale.total_profit,
    sale.return_status,
    demo.cd_gender,
    demo.cd_marital_status,
    demo.cd_purchase_estimate,
    demo.cd_credit_rating,
    demo.cd_dep_count,
    demo.cd_dep_college_count,
    CASE 
        WHEN GREATEST(sale.return_quantity, sale.sales_count) = sale.return_quantity THEN 'High Return'
        ELSE 'Low Return'
    END AS return_insight,
    STRING_AGG(CONCAT('Order:', sale.cs_order_number, ' Profit:', sale.total_profit), ', ') AS detailed_orders
FROM HighProfitSales AS sale
JOIN CustomerDemographics AS demo ON demo.c_customer_id = sale.i_item_id  -- assuming i_item_id relates to customer
GROUP BY 
    sale.i_product_name, 
    sale.total_profit, 
    sale.return_status, 
    demo.cd_gender, 
    demo.cd_marital_status, 
    demo.cd_purchase_estimate, 
    demo.cd_credit_rating, 
    demo.cd_dep_count, 
    demo.cd_dep_college_count
ORDER BY 
    sale.total_profit DESC, 
    demo.cd_gender;
