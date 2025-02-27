WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT sup.s_suppkey, sup.s_name, sup.s_nationkey, sup.s_acctbal
    FROM supplier sup
    INNER JOIN SupplierHierarchy sh ON sup.s_nationkey = sh.s_nationkey
    WHERE sup.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, co.total_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (
        SELECT AVG(total_spent)
        FROM CustomerOrders
    )
),
TopParts AS (
    SELECT p.p_partkey, p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM part p
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY p.p_partkey, p.p_name
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT DISTINCT 
    p.p_name,
    COALESCE(sh.s_name, 'N/A') AS supplier_name,
    hvc.c_name AS customer_name,
    tp.total_revenue,
    CASE WHEN tp.total_revenue > 100000 THEN 'High' ELSE 'Low' END AS revenue_category
FROM TopParts tp
LEFT JOIN partsupp ps ON tp.p_partkey = ps.ps_partkey
LEFT JOIN supplier sh ON ps.ps_suppkey = sh.s_suppkey
LEFT JOIN HighValueCustomers hvc ON hvc.c_custkey = sh.s_nationkey
WHERE sh.s_acctbal IS NOT NULL
ORDER BY tp.total_revenue DESC, hvc.total_spent DESC;
