WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice IS NOT NULL
),
TopSuppliers AS (
    SELECT s_nationkey, s_suppkey, SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM SupplyChain
    WHERE rn <= 5
    GROUP BY s_nationkey, s_suppkey
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(ts.s_suppkey) AS supplier_count,
           SUM(ts.total_supply_cost) AS total_cost, AVG(ts.total_supply_cost) AS avg_cost
    FROM nation n
    LEFT JOIN TopSuppliers ts ON n.n_nationkey = ts.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY total_cost DESC
)
SELECT ns.n_name, ns.supplier_count, COALESCE(ns.total_cost, 0) AS total_cost,
       COALESCE(ns.avg_cost, 0) AS avg_cost,
       CASE WHEN ns.total_cost IS NULL THEN 'No Supply' ELSE 'Has Supply' END AS supply_status
FROM NationStats ns
WHERE ns.supplier_count > 0 OR ns.total_cost IS NOT NULL
UNION ALL
SELECT n.n_name, 0 AS supplier_count, 0 AS total_cost, 0 AS avg_cost, 'No Supply' AS supply_status
FROM nation n
WHERE NOT EXISTS (SELECT 1 FROM TopSuppliers ts WHERE ts.s_nationkey = n.n_nationkey)
ORDER BY total_cost DESC, n_name;
