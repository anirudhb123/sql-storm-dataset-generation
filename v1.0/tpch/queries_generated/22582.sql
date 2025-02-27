WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierAvailability AS (
    SELECT ps.ps_partkey, 
           SUM(ps.ps_availqty) AS total_available, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RecentOrders AS (
    SELECT o.o_orderkey, 
           COUNT(DISTINCT l.l_orderkey) AS total_line_items,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_amount
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= (CURRENT_DATE - INTERVAL '1 YEAR')
    GROUP BY o.o_orderkey
)
SELECT 
    rp.p_partkey, 
    rp.p_name, 
    sa.total_available, 
    sa.avg_supply_cost,
    CASE 
        WHEN sa.total_available IS NULL THEN 'No Supply Data'
        ELSE CAST(sa.total_available AS VARCHAR) || ' Available'
    END AS supply_review,
    ro.total_amount,
    ro.total_line_items,
    ROW_NUMBER() OVER (PARTITION BY rp.p_partkey ORDER BY ro.total_amount DESC) AS order_rank
FROM RankedParts rp
LEFT JOIN SupplierAvailability sa ON rp.p_partkey = sa.ps_partkey
FULL OUTER JOIN RecentOrders ro ON ro.total_line_items > 0 AND sa.total_available IS NOT NULL
WHERE rp.price_rank <= 5
AND (ro.total_amount BETWEEN 1000 AND 5000 OR ro.total_amount IS NULL)
OR (sa.avg_supply_cost IS NOT NULL AND sa.avg_supply_cost < 20.00)
ORDER BY rp.p_partkey, order_rank DESC NULLS LAST
FETCH FIRST 50 ROWS ONLY;
