WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(total_cost) FROM (
        SELECT SUM(ps_supplycost * ps_availqty) AS total_cost
        FROM partsupp ps
        GROUP BY ps_suppkey
    ) AS avg_cost)
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, 
    ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderstatus = 'A'
    AND o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
),
FilteredLineItems AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM lineitem l
    JOIN RecentOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY l.l_orderkey
),
FinalOutput AS (
    SELECT p.p_name AS part_name, r.r_name AS region_name, 
           SUM(fli.revenue) AS total_revenue, 
           COUNT(DISTINCT sh.s_suppkey) AS suppliers_count
    FROM part p
    LEFT JOIN nation n ON p.p_partkey = n.n_nationkey
    LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN FilteredLineItems fli ON p.p_partkey = fli.l_orderkey
    LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
    WHERE p.p_retailprice IS NOT NULL
    AND (p.p_size = ANY(ARRAY[10, 20]) OR r.r_name IS NULL)
    GROUP BY p.p_name, r.r_name
)
SELECT part_name, region_name, total_revenue, suppliers_count
FROM FinalOutput
WHERE total_revenue > (SELECT AVG(total_revenue) FROM FinalOutput) 
ORDER BY total_revenue DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
