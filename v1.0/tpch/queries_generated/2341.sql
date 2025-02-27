WITH RECURSIVE supplier_hierarchy AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        s.s_acctbal,
        0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT 
        sp.s_suppkey, 
        sp.s_name, 
        sp.s_nationkey, 
        sp.s_acctbal,
        sh.level + 1
    FROM supplier_hierarchy sh
    JOIN supplier sp ON sh.s_nationkey = sp.s_nationkey AND sp.s_acctbal > sh.s_acctbal
)
SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(o.o_totalprice) AS avg_order_total,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    GROUP_CONCAT(DISTINCT CONCAT(p.p_name, ' (', ps.ps_availqty, ')') ORDER BY p.p_name SEPARATOR ', ') AS parts_available,
    ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY SUM(l.l_extendedprice) DESC) AS revenue_rank
FROM nation n
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
  AND o.o_orderstatus IN ('O', 'F')
  AND (l.l_returnflag IS NULL OR l.l_returnflag = 'N')
GROUP BY n.n_nationkey, r.r_regionkey
HAVING total_revenue > 1000000
ORDER BY revenue_rank, nation_name;
