WITH RECURSIVE SupplierChain AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sc.level + 1
    FROM supplier s
    JOIN SupplierChain sc ON s.s_nationkey = sc.s_nationkey
    WHERE sc.level < 5
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS cost_rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    sc.s_name AS supplier_name,
    ps.p_name AS part_name,
    os.o_orderkey,
    os.total_revenue,
    ps.total_available,
    ps.total_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN SupplierChain sc ON n.n_nationkey = sc.s_nationkey
LEFT JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT DISTINCT o.o_orderkey
    FROM orders o
    WHERE o.o_totalprice > (SELECT AVG(o2.o_totalprice) FROM orders o2)
)
LEFT JOIN PartSupplier ps ON ps.cost_rank = 1
WHERE 
    sc.level IS NOT NULL
    AND os.total_revenue IS NOT NULL
ORDER BY r.r_name, n.n_name, os.total_revenue DESC;
