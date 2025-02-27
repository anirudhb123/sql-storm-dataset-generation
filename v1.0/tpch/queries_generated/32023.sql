WITH RECURSIVE NationHierarchy AS (
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, 0 as depth
    FROM nation n
    WHERE n.n_regionkey IS NOT NULL
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.depth + 1
    FROM nation n
    INNER JOIN NationHierarchy nh ON n.n_regionkey = nh.n_nationkey
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey
),
GroupedParts AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_availqty) AS total_available,
        STRING_AGG(s.s_name, ', ') AS supplier_names
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    AVG(o.total_revenue) AS avg_revenue_per_order,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(sp.total_cost) AS total_supplier_cost,
    MAX(gp.total_available) AS max_available_parts,
    COUNT(DISTINCT nh.n_name) AS total_nations
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN OrderStats o ON o.o_orderkey IN (SELECT o_orderkey FROM orders LIMIT 100)
LEFT JOIN SupplierPerformance sp ON sp.s_suppkey IN (SELECT ps_suppkey FROM partsupp LIMIT 100)
LEFT JOIN GroupedParts gp ON gp.p_partkey IN (SELECT p_partkey FROM part LIMIT 100)
JOIN NationHierarchy nh ON nh.n_regionkey = r.r_regionkey
GROUP BY r.r_name
ORDER BY avg_revenue_per_order DESC
LIMIT 10;
