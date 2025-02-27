WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 0 AND sh.level < 3
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
PartSupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost) AS total_supplycost,
        AVG(ps.ps_availqty) AS avg_availqty
    FROM partsupp ps
    GROUP BY ps.ps_partkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    r.r_name AS region,
    COALESCE(ss.total_revenue, 0) AS total_revenue,
    COALESCE(pss.total_supplycost, 0) AS total_supplycost,
    CASE 
        WHEN ss.distinct_suppliers IS NULL THEN 'No Orders'
        ELSE 'Orders present'
    END AS order_status
FROM part p
LEFT JOIN PartSupplierSummary pss ON p.p_partkey = pss.ps_partkey
LEFT JOIN (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
) ss ON p.p_partkey = ss.o_orderkey
JOIN nation n ON n.n_nationkey = (SELECT s.s_nationkey FROM supplier s WHERE s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey) LIMIT 1)
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_size BETWEEN 1 AND 25
ORDER BY total_revenue DESC NULLS LAST, p.p_name ASC;
