WITH RECURSIVE SupplyHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS hierarchy_level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.hierarchy_level + 1
    FROM supplier s
    JOIN SupplyHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.suppkey <> sh.s_suppkey
),
TopNations AS (
    SELECT n.n_name, SUM(o.o_totalprice) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
    ORDER BY total_sales DESC
    LIMIT 5
),
CustomerStats AS (
    SELECT c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_name
    HAVING total_spent > 1000
),
RankedPartSales AS (
    SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
           RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
)
SELECT 
    COALESCE(tp.n_name, 'Unknown') AS nation,
    COUNT(DISTINCT cs.c_name) AS active_customers,
    SUM(rps.net_revenue) AS total_revenue,
    MAX(rps.revenue_rank) AS max_rank
FROM TopNations tp
FULL OUTER JOIN CustomerStats cs ON tp.n_name = cs.c_name
FULL OUTER JOIN RankedPartSales rps ON tp.n_name = rps.p_name
WHERE (MAX(cs.order_count) IS NULL OR MAX(cs.order_count) > 5)
AND (tp.total_sales > 100)
GROUP BY tp.n_name
ORDER BY total_revenue DESC;
