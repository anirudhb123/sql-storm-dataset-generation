WITH RECURSIVE PartHierarchy AS (
    SELECT p_partkey, p_name, p_mfgr, p_brand, p_type, p_size, p_container, p_retailprice, p_comment, 1 AS level
    FROM part
    WHERE p_size >= 10
    UNION ALL
    SELECT p.ps_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment, ph.level + 1
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN PartHierarchy ph ON ps.ps_suppkey = ph.p_partkey
)
SELECT n.n_name AS nation, 
       r.r_name AS region, 
       COUNT(DISTINCT c.c_custkey) AS customers_count,
       SUM(o.o_totalprice) AS total_sales,
       AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_discounted_price,
       SUM(l.l_quantity) AS total_quantity,
       MAX(ph.p_retailprice) AS max_part_price
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN PartHierarchy ph ON ph.p_partkey = l.l_partkey
WHERE r.r_name LIKE 'AS%' AND ph.level <= 3
GROUP BY n.n_name, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_sales DESC, avg_discounted_price DESC;
