WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost ASC) AS price_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
), 
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
), 
OrderTotals AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderstatus,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderstatus
)
SELECT DISTINCT 
    r.r_name, 
    CASE 
        WHEN COUNT(DISTINCT o.o_orderkey) = 0 THEN 'No Orders'
        ELSE 'Has Orders'
    END AS order_status,
    COALESCE(SUM(st.total_discounted), 0) AS total_revenue,
    MAX(s.s_name) AS supplier_name
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.price_rank = 1
LEFT JOIN HighValueCustomers hvc ON s.s_suppkey IN (
    SELECT DISTINCT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty > 300
)
LEFT JOIN OrderTotals st ON st.o_orderstatus = 'O' AND st.o_totalprice > 5000
WHERE r.r_name IS NOT NULL
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY r.r_name DESC
LIMIT 10 OFFSET 5;
