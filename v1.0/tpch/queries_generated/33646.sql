WITH RECURSIVE supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 50000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN supplier_hierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > (sh.s_acctbal / 2)
), 

order_details AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2023-10-01'
    GROUP BY o.o_orderkey, o.o_orderdate
), 

customer_ranking AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, RANK() OVER (ORDER BY c.c_acctbal DESC) as rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
)

SELECT
    r.r_name AS region_name,
    SUM(od.total_sales) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    COALESCE(SUM(s.s_acctbal), 0) AS total_supplier_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS suppliers
FROM region r
LEFT JOIN nation n ON n.n_regionkey = r.r_regionkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN part p ON p.p_partkey = ps.ps_partkey
LEFT JOIN order_details od ON p.p_partkey = od.o_orderkey
LEFT JOIN customer_ranking cr ON cr.c_custkey = od.o_orderkey
WHERE p.p_size IS NOT NULL
AND (p.p_retailprice > 1000 OR p.p_mfgr LIKE 'Manufacturer%' AND p.p_container IS NOT NULL)
AND s.s_suppkey IN (SELECT s_suppkey FROM supplier_hierarchy)
GROUP BY r.r_name
ORDER BY total_sales DESC
WITH ROLLUP;
