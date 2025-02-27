WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 0 AS level
    FROM supplier 
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    UNION ALL
    SELECT sp.s_suppkey, sp.s_name, sp.s_acctbal, sh.level + 1
    FROM supplier sp
    INNER JOIN SupplierHierarchy sh ON sp.s_suppkey = sh.s_suppkey
    WHERE sp.s_acctbal < sh.s_acctbal
),
TotalOrders AS (
    SELECT 
        c.c_custkey,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey
)
SELECT 
    r.r_name AS region_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    AVG(t.total_spent) AS average_spending,
    SUM(ps.total_supply_cost) AS total_supplier_cost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN TotalOrders t ON c.c_custkey = t.c_custkey
FULL OUTER JOIN PartSupplier ps ON 1=1
WHERE r.r_name IS NOT NULL 
GROUP BY r.r_name, n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 10 AND AVG(t.total_spent) IS NOT NULL
ORDER BY total_supplier_cost DESC, average_spending DESC;
