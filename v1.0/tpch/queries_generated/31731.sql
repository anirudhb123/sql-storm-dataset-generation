WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 1000 AND sh.level < 5
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY c.c_custkey, c.c_name
),
PartSupplierSummary AS (
    SELECT p.p_partkey, p.p_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, total_spent, ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM CustomerOrders c
    WHERE total_spent IS NOT NULL
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
)
SELECT 
    r.r_name,
    COUNT(DISTINCT nh.n_nationkey) AS total_nations,
    SUM(p.total_supply_cost) AS total_part_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    COALESCE(MAX(ru.rank), 0) AS max_customer_rank
FROM region r
LEFT JOIN nation nh ON r.r_regionkey = nh.n_regionkey
LEFT JOIN PartSupplierSummary p ON p.p_partkey IN (
    SELECT ps.ps_partkey
    FROM partsupp ps
    JOIN HighValueSuppliers s ON ps.ps_suppkey = s.s_suppkey
)
LEFT JOIN RankedCustomers ru ON ru.total_spent IS NOT NULL
GROUP BY r.r_name
ORDER BY r.r_name;
