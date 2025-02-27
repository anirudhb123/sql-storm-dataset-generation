WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_nationkey = s.s_nationkey
    WHERE sh.level < 5
),
SupplierPerformance AS (
    SELECT 
        sp.ps_partkey,
        SUM(sp.ps_availqty) AS total_availability,
        AVG(sp.ps_supplycost) AS avg_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY sp.ps_partkey ORDER BY AVG(sp.ps_supplycost) DESC) AS rn
    FROM partsupp sp
    GROUP BY sp.ps_partkey
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_partkey) AS total_parts,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        MAX(l.l_shipdate) AS latest_ship_date,
        MIN(l.l_shipdate) AS earliest_ship_date,
        l.l_returnflag,
        l.l_linestatus
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, l.l_returnflag, l.l_linestatus
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    COALESCE(sp.avg_supply_cost, 0) AS avg_supply_cost,
    COALESCE(op.total_parts, 0) AS total_parts_in_orders,
    op.total_value,
    sr.r_name AS supplier_region,
    sh.level AS supplier_level
FROM part p
LEFT JOIN SupplierPerformance sp ON p.p_partkey = sp.ps_partkey AND sp.rn = 1
JOIN OrderDetails op ON p.p_partkey = op.o_orderkey
LEFT JOIN region sr ON sr.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey IN (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT sh.s_suppkey FROM SupplierHierarchy sh)))
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey = op.o_orderkey)
WHERE p.p_retailprice > 100
  AND (op.latest_ship_date IS NOT NULL OR op.earliest_ship_date IS NULL)
ORDER BY total_value DESC
LIMIT 50;
