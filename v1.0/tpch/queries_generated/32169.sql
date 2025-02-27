WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_brand, p_retailprice, 0 AS level
    FROM part
    WHERE p_size < 20
    UNION ALL
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice * 0.9, ph.level + 1
    FROM part p
    JOIN PartHierarchy ph ON p.p_partkey = ph.p_partkey + 1
    WHERE ph.level < 5
),
SupplierPricing AS (
    SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_cost, AVG(ps.ps_supplycost) AS avg_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
RankedOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS price_rank
    FROM orders o
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
)
SELECT ph.p_partkey, ph.p_name, ph.p_brand, ph.p_retailprice, sp.total_cost, ro.price_rank
FROM PartHierarchy ph
LEFT JOIN SupplierPricing sp ON ph.p_partkey = sp.ps_partkey
FULL OUTER JOIN RankedOrders ro ON sp.ps_partkey = ro.o_orderkey
WHERE ph.p_retailprice > COALESCE(sp.total_cost, 0) * 1.1
  AND (ph.p_name LIKE 'A%' OR ph.p_brand IS NULL)
ORDER BY ph.p_partkey DESC, ro.price_rank ASC
LIMIT 100;
