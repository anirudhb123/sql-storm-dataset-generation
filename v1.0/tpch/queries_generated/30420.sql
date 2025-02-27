WITH RECURSIVE OrderHierarchy AS (
    SELECT o.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           1 AS level,
           CAST(o.o_orderkey AS varchar) AS path
    FROM orders o
    WHERE o.o_orderdate >= '2021-01-01'

    UNION ALL

    SELECT oh.o_orderkey,
           o.o_orderdate,
           o.o_totalprice,
           oh.level + 1,
           CONCAT(oh.path, ' -> ', o.o_orderkey)
    FROM orders o
    JOIN OrderHierarchy oh ON o.o_custkey = (
        SELECT c.c_custkey
        FROM customer c
        WHERE c.c_custkey = o.o_custkey
        AND c.c_acctbal > 10000
        LIMIT 1
    )
    WHERE o.o_orderdate < CURRENT_DATE
)

SELECT r.r_name,
       COUNT(DISTINCT s.s_supplycost) AS num_suppliers,
       SUM(ps.ps_availqty) AS total_available_quantity,
       AVG(l.l_extendedprice) AS avg_price,
       STRING_AGG(DISTINCT p.p_name, ', ') AS part_names
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
WHERE s.s_acctbal IS NOT NULL
  AND p.p_size IS NOT NULL
  AND l.l_shipdate BETWEEN '2021-01-01' AND '2023-12-31'
  AND EXISTS (SELECT 1 FROM orders o WHERE o.o_orderkey = l.l_orderkey AND o.o_orderstatus = 'F')
GROUP BY r.r_name
HAVING COUNT(DISTINCT ps.ps_partkey) > 10
ORDER BY total_available_quantity DESC;
