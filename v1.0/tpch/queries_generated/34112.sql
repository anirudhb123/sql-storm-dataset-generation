WITH RECURSIVE part_supplier_hierarchy AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, 1 AS level
    FROM partsupp ps
    WHERE ps.ps_availqty > 10

    UNION ALL

    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty
    FROM partsupp ps
    INNER JOIN part_supplier_hierarchy psh ON ps.ps_partkey = psh.ps_partkey
    WHERE ps.ps_availqty < psh.ps_availqty
),

customer_summary AS (
    SELECT c.c_custkey, c.c_name, 
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

nation_region AS (
    SELECT n.n_nationkey, n.n_name, r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY n.n_name) AS rank
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
)

SELECT p.p_name, p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(MAX(s.s_acctbal), 0) AS max_supplier_balance,
    COUNT(DISTINCT c.c_custkey) AS unique_customer_count,
    nr.r_name,
    CASE WHEN nr.rank <= 5 THEN 'Top Region' ELSE 'Other' END AS region_category
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN supplier s ON l.l_suppkey = s.s_suppkey
LEFT JOIN customer_summary cs ON o.o_custkey = cs.c_custkey
JOIN nation_region nr ON s.s_nationkey = nr.n_nationkey
WHERE p.p_retailprice > 50.00 AND p.p_container IS NOT NULL 
AND (l.l_returnflag IS NULL OR l.l_returnflag = 'R')
GROUP BY p.p_name, p.p_brand, nr.r_name, nr.rank
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY revenue DESC, order_count DESC;
