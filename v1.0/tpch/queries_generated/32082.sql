WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
)
SELECT sh.s_name AS supplier_name, sh.level AS hierarchy_level, os.total_revenue,
       sd.nation_name, sd.total_supply_cost
FROM SupplierHierarchy sh
LEFT JOIN OrderSummary os ON sh.s_nationkey = (
    SELECT c.c_nationkey
    FROM customer c
    WHERE c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = (SELECT MIN(o2.o_orderkey) FROM orders o2))
    )
)
LEFT JOIN SupplierDetails sd ON sh.s_suppkey = sd.s_suppkey
WHERE sd.total_supply_cost IS NOT NULL
ORDER BY sh.level DESC, os.total_revenue DESC
LIMIT 10;
