WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, 1 AS level
    FROM supplier
    WHERE s_acctbal > (
        SELECT AVG(s_acctbal) FROM supplier
    )
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(co.total_spent) AS total_customer_spent
    FROM customer c
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_customer_spent DESC
    LIMIT 10
),
PartSupplierDetails AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
)
SELECT 
    th.c_name AS CustomerName, 
    th.total_customer_spent AS TotalSpent, 
    p.p_name AS ProductName, 
    ps.total_supply_cost AS TotalSupplyCost,
    (SELECT COUNT(DISTINCT n.n_nationkey) 
     FROM nation n 
     WHERE n.n_nationkey IN (SELECT s_nationkey FROM supplier WHERE s_suppkey IN (SELECT ps_suppkey FROM partsupp WHERE ps_partkey = p.p_partkey))
    ) AS DistinctNationsSupplyingProduct
FROM TopCustomers th
JOIN PartSupplierDetails ps ON th.total_customer_spent > ps.total_supply_cost
JOIN part p ON p.p_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_suppkey IN (SELECT s_suppkey FROM supplier WHERE s_nationkey = th.c_custkey))
ORDER BY TotalSpent DESC, TotalSupplyCost ASC;
