WITH RecursiveSupplier AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, rs.level + 1
    FROM supplier s
    JOIN RecursiveSupplier rs ON s.s_suppkey = rs.s_suppkey
    WHERE rs.level < 5
),
PartSupplier AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty * 1.2 AS adjusted_availqty
    FROM partsupp ps
    WHERE ps.ps_availqty IS NOT NULL
),
OrderLineStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(l.l_linenumber) AS line_count,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS price_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_acctbal IS NOT NULL)
)
SELECT 
    p.p_name,
    COALESCE(r.r_name, 'Unknown Region') AS region_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(COALESCE(rg.adjusted_availqty, 0)) AS total_adjusted_availqty,
    COALESCE(SUM(ols.total_price), 0) AS total_orders_value,
    GROUP_CONCAT(DISTINCT c.c_name ORDER BY c.c_custkey) AS customer_names
FROM part p
LEFT JOIN partSupplier ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN region r ON EXISTS (SELECT 1 FROM nation n WHERE n.n_nationkey = (SELECT s_nationkey FROM supplier s WHERE ps.ps_suppkey = s.s_suppkey) AND n.n_regionkey = r.r_regionkey)
LEFT JOIN OrderLineStats ols ON p.p_partkey = (SELECT l.l_partkey FROM lineitem l WHERE l.l_orderkey = ols.o_orderkey LIMIT 1)
FULL OUTER JOIN HighValueCustomers c ON c.c_custkey = (SELECT o.o_custkey FROM orders o WHERE o.o_orderkey = ols.o_orderkey LIMIT 1)
GROUP BY p.p_partkey, p.p_name, r.r_name
HAVING SUM(ps.ps_availqty) > 0 OR COUNT(DISTINCT c.c_custkey) >= 5
ORDER BY supplier_count DESC, total_orders_value DESC
LIMIT 100 OFFSET 10;
