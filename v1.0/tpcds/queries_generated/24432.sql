
WITH RankedReturns AS (
    SELECT 
        wr.returning_customer_sk, 
        SUM(wr.return_quantity) AS total_returned_quantity,
        AVG(wr.return_amt) AS avg_return_amount,
        ROW_NUMBER() OVER (PARTITION BY wr.returning_customer_sk ORDER BY SUM(wr.return_quantity) DESC) AS rank
    FROM web_returns wr
    GROUP BY wr.returning_customer_sk
),
CustomerWithDemographics AS (
    SELECT 
        c.c_customer_id,
        cd.cd_gender,
        cd.cd_marital_status,
        cd.cd_purchase_estimate,
        ROW_NUMBER() OVER (PARTITION BY cd.cd_gender ORDER BY cd.cd_purchase_estimate DESC) AS gender_rank
    FROM customer c
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_purchase_estimate IS NOT NULL
),
InventoryDetails AS (
    SELECT 
        i.i_item_id,
        i.i_current_price,
        COALESCE(SUM(i.inv_quantity_on_hand), 0) AS total_inventory,
        i.i_item_desc,
        RANK() OVER (ORDER BY COALESCE(SUM(i.inv_quantity_on_hand), 0) DESC) AS inventory_rank
    FROM item i
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    GROUP BY i.i_item_id, i.i_current_price, i.i_item_desc
)
SELECT 
    c.c_customer_id,
    cd.cd_gender,
    cd.cd_marital_status,
    rr.total_returned_quantity,
    rr.avg_return_amount,
    id.i_item_id,
    id.i_current_price,
    id.total_inventory,
    id.i_item_desc
FROM CustomerWithDemographics cd
JOIN RankedReturns rr ON cd.customer_id = rr.returning_customer_sk
JOIN InventoryDetails id ON rr.total_returned_quantity > 0 
WHERE EXISTS (
    SELECT 1 
    FROM promotion p 
    WHERE p.p_item_sk = id.i_item_id 
      AND p.p_discount_active = 'Y'
) 
AND (cd.cd_marital_status IS NOT NULL OR cd.cd_gender IS NOT NULL)
ORDER BY 
    cd.gender_rank,
    rr.total_returned_quantity DESC,
    id.inventory_rank
FETCH FIRST 100 ROWS ONLY;
