WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT ps.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM partsupp ps
    JOIN SupplierHierarchy sh ON ps.ps_suppkey = sh.s_suppkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_acctbal < sh.s_acctbal AND sh.level < 10
),
AggregatedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN '2022-01-01' AND '2022-12-31'
    GROUP BY o.o_orderkey
),
CustomerWithTopOrder AS (
    SELECT c.c_custkey, c.c_name, 
           RANK() OVER (PARTITION BY c.c_nationkey ORDER BY a.total_revenue DESC) AS order_rank
    FROM customer c
    JOIN AggregatedOrders a ON c.c_custkey = a.o_orderkey
)
SELECT DISTINCT 
    p.p_partkey,
    p.p_name,
    s.s_name AS supplier_name,
    COALESCE(n.n_name, 'Unknown Nation') AS nation_name,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS ranked_supplier,
    CASE 
        WHEN MAX(o.o_totalprice) IS NULL THEN 'No Orders'
        ELSE concat('Total Orders: ', CAST(MAX(o.o_totalprice) AS varchar))
    END AS order_summary
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN orders o ON o.o_orderkey = (SELECT MIN(o2.o_orderkey) 
                                        FROM orders o2 
                                        WHERE o2.o_custkey IN (SELECT c_custkey FROM CustomerWithTopOrder WHERE order_rank = 1))
WHERE p.p_size > 10 AND (s.s_acctbal IS NULL OR s.s_acctbal > 5000)
GROUP BY p.p_partkey, p.p_name, s.s_name, n.n_name
ORDER BY p.p_partkey DESC, ranked_supplier;
