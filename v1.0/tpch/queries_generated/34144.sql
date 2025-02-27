WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (
        SELECT AVG(s_acctbal)
        FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey <> sh.s_suppkey AND SUBSTRING(s.s_name, 1, sh.level) = SUBSTRING(sh.s_name, 1, sh.level)
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey
),
part_supplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    AVG(sh.s_acctbal) AS avg_acctbal,
    SUM(os.total_revenue) AS total_order_revenue,
    STRING_AGG(DISTINCT ps.p_name, ', ') AS popular_parts
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
LEFT JOIN order_summary os ON os.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = s.s_suppkey)
LEFT JOIN part_supplier ps ON ps.rank = 1
WHERE n.n_name IS NOT NULL
GROUP BY n.n_name
ORDER BY avg_acctbal DESC, supplier_count ASC
LIMIT 10;
