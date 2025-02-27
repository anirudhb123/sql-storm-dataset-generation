WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_orderstatus, 
           RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM orders o
    WHERE o.o_orderdate >= DATE '2023-01-01'
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerSpending AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name
    FROM CustomerSpending c
    ORDER BY c.total_spent DESC
    LIMIT 10
)
SELECT 
    r.r_name AS Region_Name,
    COUNT(DISTINCT s.s_suppkey) AS Number_of_Suppliers,
    AVG(sd.total_supply_cost) AS Average_Supply_Cost,
    SUM(CASE WHEN ro.o_orderstatus = 'O' THEN 1 ELSE 0 END) AS Open_Orders,
    SUM(CASE WHEN ro.o_orderstatus = 'F' THEN 1 ELSE 0 END) AS Finished_Orders
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN supplier s ON n.n_nationkey = s.s_nationkey
JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
JOIN RankedOrders ro ON ro.o_orderkey IN (
    SELECT l.l_orderkey
    FROM lineitem l
    WHERE l.l_suppkey = s.s_suppkey
)
JOIN TopCustomers tc ON tc.c_custkey = ro.o_custkey
GROUP BY r.r_name
ORDER BY Number_of_Suppliers DESC, Average_Supply_Cost ASC;
