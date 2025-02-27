WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey 
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost, 
           (ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty < 100
),
SalesData AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, 
           SUM(l.l_quantity * l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, SUM(sd.total_sales) AS total_spent
    FROM SalesData sd
    JOIN customer c ON sd.c_custkey = c.c_custkey
    GROUP BY c.c_custkey, c.c_name
    ORDER BY total_spent DESC
    LIMIT 10
)
SELECT ph.s_name, pt.p_name, pt.total_supply_cost, tc.total_spent
FROM SupplierHierarchy ph
FULL OUTER JOIN PartAvailability pt ON ph.s_suppkey = pt.p_partkey
RIGHT JOIN TopCustomers tc ON ph.s_suppkey = tc.c_custkey
WHERE pt.total_supply_cost IS NOT NULL
  OR tc.total_spent IS NOT NULL
ORDER BY ph.level, tc.total_spent DESC;
