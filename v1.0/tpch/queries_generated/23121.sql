WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           CAST(s.s_name AS VARCHAR(100)) AS path
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           CONCAT(sh.path, ' -> ', s.s_name)
    FROM supplier s
    JOIN SupplierHierarchy sh ON sh.s_suppkey = s.s_suppkey
    WHERE s.s_acctbal IS NOT NULL AND s.s_acctbal > sh.s_acctbal
),
CustomerOrderStats AS (
    SELECT c.c_custkey,
           COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
    HAVING COUNT(DISTINCT o.o_orderkey) > 0
),
PartStats AS (
    SELECT p.p_partkey,
           AVG(ps.ps_supplycost) AS average_supplycost,
           SUM(CASE WHEN l.l_shipdate < CURRENT_DATE THEN l.l_extendedprice ELSE 0 END) AS total_previous_revenue
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    LEFT JOIN lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY p.p_partkey
)
SELECT 
    R.r_name,
    N.n_name,
    C.c_name,
    COALESCE(O.order_count, 0) AS total_orders,
    COALESCE(P.average_supplycost, 0) AS avg_supply_cost,
    SUM(P.total_previous_revenue) AS total_revenue,
    COUNT(S.s_suppkey) FILTER (WHERE S.s_acctbal IS NOT NULL) AS active_suppliers
FROM region R
JOIN nation N ON R.r_regionkey = N.n_regionkey
LEFT JOIN customer C ON N.n_nationkey = C.c_nationkey
LEFT JOIN CustomerOrderStats O ON C.c_custkey = O.c_custkey
LEFT JOIN PartStats P ON P.p_partkey IN (SELECT ps.partkey 
                                           FROM partsupp ps 
                                           WHERE ps.ps_supplycost = (
                                             SELECT MIN(ps_supplycost) 
                                             FROM partsupp 
                                             WHERE ps_supplycost IS NOT NULL))
LEFT JOIN supplier S ON C.c_nationkey = S.s_nationkey
GROUP BY R.r_name, N.n_name, C.c_name
ORDER BY R.r_name, N.n_name, C.c_name;
