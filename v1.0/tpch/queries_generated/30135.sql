WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier
    WHERE s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_acctbal > sh.s_acctbal
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
PartSupplier AS (
    SELECT ps.ps_partkey, p.p_name, SUM(ps.ps_availqty) AS total_avail_qty
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, p.p_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerOrders c
    WHERE total_spent > (
        SELECT AVG(total_spent) FROM CustomerOrders
    )
)

SELECT 
    p.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COALESCE(a.total_avail_qty, 0) AS total_avail_qty,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    ROW_NUMBER() OVER (PARTITION BY r.r_regionkey ORDER BY revenue DESC) AS region_rank
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN region r ON s.s_nationkey = (
    SELECT n.n_nationkey FROM nation n 
    WHERE n.n_nationkey = s.s_nationkey
)
LEFT JOIN TopCustomers c ON o.o_custkey = c.c_custkey
LEFT JOIN PartSupplier a ON ps.ps_partkey = a.ps_partkey
WHERE l.l_shipdate BETWEEN '2023-01-01' AND CURRENT_DATE
GROUP BY p.p_name, a.total_avail_qty, r.r_regionkey
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY revenue DESC;
