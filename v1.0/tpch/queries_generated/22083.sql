WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT p.p_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) < (SELECT AVG(ps_supplycost) FROM partsupp)
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           COUNT(l.l_linenumber) AS line_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT
    r.rnk,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    COALESCE(ROUND(SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_extendedprice END), 2), 0) AS total_sales,
    COALESCE(p.p_name, 'No Parts Sold') AS part_name,
    SUM(COALESCE(l.l_quantity, 0)) AS total_quantity,
    MAX(COALESCE(o.o_orderdate, '1970-01-01')) AS last_order_date,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM RankedSuppliers r
FULL OUTER JOIN RecentOrders o ON r.s_suppkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN HighValueParts hp ON l.l_partkey = hp.p_partkey
LEFT JOIN part p ON hp.p_partkey = p.p_partkey
GROUP BY r.rnk, s.s_name, p.p_name
HAVING SUM(COALESCE(l.l_discount, 0)) > (SELECT AVG(l_discount) FROM lineitem WHERE l_discount IS NOT NULL)
ORDER BY r.rnk, total_sales DESC NULLS LAST;
