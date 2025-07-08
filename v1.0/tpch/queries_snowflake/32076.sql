
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_address, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_address, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE sh.level < 3
),
PartSuppliers AS (
    SELECT ps.ps_partkey, COUNT(*) AS supplier_count, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_orderstatus
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_mfgr,
    p.p_brand,
    p.p_type,
    p.p_size,
    ps.supplier_count,
    ps.total_supply_cost,
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    o.revenue,
    oh.level AS supplier_hierarchy_level
FROM part p
LEFT JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN nation n ON p.p_brand = n.n_name
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN OrderStats o ON o.revenue_rank <= 10
LEFT JOIN SupplierHierarchy oh ON n.n_nationkey = oh.s_nationkey
WHERE p.p_retailprice > 50
AND (ps.supplier_count IS NULL OR ps.supplier_count > 5)
ORDER BY p.p_partkey, o.revenue DESC NULLS LAST;
