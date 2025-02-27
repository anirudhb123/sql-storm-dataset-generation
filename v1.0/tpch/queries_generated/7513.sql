WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, 
           SUM(ps.ps_availqty) AS total_available, SUM(ps.ps_supplycost) AS total_supply_cost,
           RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_availqty) DESC) AS rank_within_nation
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
HighValueCustomers AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, c.c_mktsegment,
           ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS rank_by_balance
    FROM customer c
    WHERE c.c_acctbal > 10000
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, 
           ROW_NUMBER() OVER (ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderdate >= DATEADD(MONTH, -6, GETDATE())
)
SELECT r.nation_name, rs.s_name, rs.total_available, 
       hvc.c_name AS high_value_customer, ro.o_orderkey, ro.o_totalprice
FROM RankedSuppliers rs
JOIN nation r ON rs.nation_name = r.r_name
JOIN HighValueCustomers hvc ON rs.rank_within_nation = 1
JOIN RecentOrders ro ON hvc.c_custkey = ro.o_custkey
WHERE rs.total_supply_cost > 50000
ORDER BY r.nation_name, rs.total_available DESC;
