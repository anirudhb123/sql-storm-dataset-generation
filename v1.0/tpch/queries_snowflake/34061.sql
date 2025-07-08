
WITH RECURSIVE supplier_hierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 10000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN supplier_hierarchy sh ON s.s_nationkey = sh.s_suppkey
), part_statistics AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_type
)
SELECT 
    r.r_name,
    n.n_name,
    c.c_name,
    SUM(o.o_totalprice) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(p.total_available), 0) AS total_parts_available,
    COUNT(DISTINCT sh.s_suppkey) AS active_suppliers
FROM region r
INNER JOIN nation n ON r.r_regionkey = n.n_regionkey
INNER JOIN supplier s ON n.n_nationkey = s.s_nationkey
INNER JOIN customer c ON s.s_suppkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN part_statistics p ON p.rn = 1
LEFT JOIN supplier_hierarchy sh ON sh.s_suppkey = s.s_suppkey
WHERE o.o_orderstatus = 'O'
AND c.c_acctbal IS NOT NULL
GROUP BY r.r_name, n.n_name, c.c_name
HAVING SUM(o.o_totalprice) > 100000
ORDER BY total_sales DESC
LIMIT 10;
