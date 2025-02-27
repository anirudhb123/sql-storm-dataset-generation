WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Select suppliers with above average account balance

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5 -- Limit to 5 levels deep
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(s.s_suppkey) > 0
),
PartWithAvailability AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_availqty) AS total_available
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
    HAVING SUM(ps.ps_availqty) > 0
),
OrderDetails AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31' -- Orders from the current year
    GROUP BY o.o_orderkey
),
FinalReport AS (
    SELECT 
        n.n_name AS nation_name,
        ph.p_name AS part_name,
        SUM(od.revenue) AS total_revenue,
        SUM(pwa.total_available) AS total_available,
        COUNT(DISTINCT sh.s_suppkey) AS distinct_suppliers
    FROM TopNations n
    JOIN OrderDetails od ON od.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
        WHERE c.c_nationkey = n.n_nationkey
    )
    JOIN PartWithAvailability pwa ON od.o_orderkey IN (
        SELECT l.l_orderkey
        FROM lineitem l
        WHERE l.l_partkey IN (
            SELECT p.p_partkey
            FROM part p
            WHERE p.p_size > 10 -- Filtering parts by size
        )
    )
    LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
    GROUP BY n.n_name, ph.p_name
    ORDER BY total_revenue DESC, distinct_suppliers DESC
    LIMIT 10 -- Limit the results to top 10
)

SELECT * FROM FinalReport;
