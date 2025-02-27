WITH RECURSIVE SupplyCostCTE AS (
    SELECT ps_partkey, 
           SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
           1 AS level
    FROM partsupp
    GROUP BY ps_partkey
    HAVING SUM(ps_availqty) > 0
    UNION ALL
    SELECT p.ps_partkey, 
           SUM(p.ps_supplycost * p.ps_availqty) * (1 + (0.1 * (level - 1))) AS total_supply_cost,
           level + 1
    FROM partsupp p
    JOIN SupplyCostCTE s ON p.ps_partkey = s.ps_partkey
    WHERE level < 5
    GROUP BY p.ps_partkey, level
),
PartStats AS (
    SELECT p.p_partkey, 
           p.p_name,
           COUNT(DISTINCT ps.s_suppkey) AS supplier_count,
           AVG(l.l_discount) AS avg_discount,
           MAX(p.p_retailprice) AS max_price
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
NationStats AS (
    SELECT n.n_nationkey,
           n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
           SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT ps.p_partkey, 
       ps.p_name, 
       ns.n_name AS supplier_nation,
       ps.supplier_count,
       ps.avg_discount,
       COALESCE(scc.total_supply_cost, 0) AS total_supply_cost,
       ns.total_suppliers,
       ns.total_acctbal,
       CASE 
           WHEN ps.avg_discount IS NULL THEN 'No Discounts'
           ELSE CASE 
                WHEN ps.avg_discount > 0.1 THEN 'High Discounts'
                ELSE 'Low Discounts' 
                END
       END AS discount_category
FROM PartStats ps
LEFT JOIN SupplyCostCTE scc ON ps.p_partkey = scc.ps_partkey
JOIN NationStats ns ON ps.supplier_count = ns.total_suppliers
WHERE ps.max_price > 50
  AND (ns.total_acctbal IS NULL OR ns.total_acctbal > 1000)
ORDER BY ps.p_partkey, ns.n_name
LIMIT 100
OFFSET (SELECT COUNT(*) FROM part) % 50;
