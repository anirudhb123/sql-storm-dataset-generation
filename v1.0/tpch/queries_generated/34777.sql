WITH RECURSIVE nation_hierarchy AS (
    SELECT n_nationkey, n_name, n_regionkey, 1 AS level
    FROM nation
    WHERE n_regionkey IN (SELECT r_regionkey FROM region WHERE r_name = 'ASIA')
    UNION ALL
    SELECT n.n_nationkey, n.n_name, n.n_regionkey, nh.level + 1
    FROM nation n
    JOIN nation_hierarchy nh ON n.n_regionkey = nh.n_nationkey
),
supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
),
aggregated_orders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
           COUNT(DISTINCT l.l_linestatus) AS line_status_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '2023-01-01' AND o.o_orderstatus = 'O'
    GROUP BY o.o_orderkey, o.o_custkey
)
SELECT p.p_partkey, p.p_name, 
       COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       AVG(s.s_acctbal) AS average_balance,
       (SELECT COUNT(DISTINCT c.c_custkey)
        FROM customer c
        WHERE c.c_nationkey = s.s_nationkey) AS customer_count,
       ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY p.p_retailprice DESC) AS retail_rank
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier_info s ON ps.ps_suppkey = s.s_suppkey AND s.rank <= 5
LEFT JOIN aggregated_orders ao ON ao.o_custkey = s.s_nationkey
WHERE p.p_size BETWEEN 5 AND 10
  AND p.p_retailprice >= (SELECT AVG(p2.p_retailprice) 
                          FROM part p2 
                          WHERE p2.p_container IS NULL)
GROUP BY p.p_partkey, p.p_name
HAVING COUNT(DISTINCT ao.o_orderkey) > 10
ORDER BY supplier_count DESC, average_balance ASC;
