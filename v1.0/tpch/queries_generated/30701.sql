WITH RECURSIVE Nation_Supplier AS (
    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    WHERE s.s_acctbal > 1000.00

    UNION ALL

    SELECT n.n_nationkey, n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN Nation_Supplier ns ON n.n_nationkey = ns.n_nationkey
    WHERE s.s_acctbal <= 1000.00
),
Aggregate_Summary AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
),
Max_Revenue AS (
    SELECT 
        part_summary.p_partkey,
        part_summary.p_name,
        part_summary.total_revenue,
        ns.s_name,
        ns.s_acctbal
    FROM Aggregate_Summary part_summary
    LEFT JOIN Nation_Supplier ns ON part_summary.p_partkey = ns.n_nationkey
    WHERE ns.s_acctbal IS NOT NULL
)
SELECT 
    r.r_name,
    COALESCE(MAX(mr.total_revenue), 0) AS max_revenue,
    COUNT(DISTINCT mr.s_name) AS supplier_count
FROM region r
LEFT JOIN Max_Revenue mr ON mr.p_partkey IN (SELECT p_partkey FROM part WHERE p_size > 10)
GROUP BY r.r_name
ORDER BY max_revenue DESC, supplier_count DESC;
