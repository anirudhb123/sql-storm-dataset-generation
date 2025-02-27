
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal IS NOT NULL
),
OrderStats AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
NationRegionSummary AS (
    SELECT n.n_nationkey, r.r_regionkey, COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, r.r_regionkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_container,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(ps.ps_supplycost) AS average_supply_cost,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice) DESC) AS price_rank,
    CASE 
        WHEN SUM(l.l_extendedprice) > 10000 THEN 'High Revenue'
        WHEN SUM(l.l_extendedprice) BETWEEN 5000 AND 10000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    COALESCE(ns.supplier_count, 0) AS nation_supplier_count,
    (SELECT COUNT(*) FROM OrderStats os WHERE os.total_revenue > 10000) AS high_revenue_order_count
FROM 
    part p
LEFT JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    (SELECT n.n_nationkey, ns.supplier_count FROM NationRegionSummary ns JOIN nation n ON ns.n_nationkey = n.n_nationkey) ns ON ns.n_nationkey = p.p_partkey
GROUP BY 
    p.p_name, p.p_brand, p.p_container, ns.supplier_count, p.p_partkey
HAVING 
    SUM(ps.ps_availqty) > 0
ORDER BY 
    total_available_quantity DESC, average_supply_cost ASC;
