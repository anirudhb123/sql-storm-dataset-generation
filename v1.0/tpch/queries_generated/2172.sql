WITH SupplierData AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, 
           o.o_orderkey, o.o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
),
TopCustomers AS (
    SELECT c.c_nationkey, SUM(o.o_totalprice) AS total_spent
    FROM CustomerOrders o
    JOIN customer c ON o.c_custkey = c.c_custkey
    WHERE o.rn = 1
    GROUP BY c.c_nationkey
)
SELECT r.r_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       COALESCE(SUM(sd.total_supply_cost), 0) AS total_supply_cost,
       COALESCE(SUM(tc.total_spent), 0) AS total_customer_spending
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierData sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN TopCustomers tc ON n.n_nationkey = tc.c_nationkey
GROUP BY r.r_name
ORDER BY r.r_name;
