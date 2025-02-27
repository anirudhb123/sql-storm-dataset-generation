WITH RECURSIVE RankedNations AS (
    SELECT n.n_name, n.n_regionkey, 
           ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(s.s_acctbal) DESC) as rank
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name, n.n_regionkey
), 
TopSuppliers AS (
    SELECT s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), 
CustomerCounts AS (
    SELECT c.c_nationkey, COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM customer c
    GROUP BY c.c_nationkey
), 
TotalOrders AS (
    SELECT o.o_custkey, SUM(o.o_totalprice) AS total_order_value
    FROM orders o
    GROUP BY o.o_custkey
)
SELECT rn.n_name, ts.s_name, cc.customer_count, to.total_order_value
FROM RankedNations rn
JOIN TopSuppliers ts ON rn.n_regionkey = ts.s_nationkey
JOIN CustomerCounts cc ON ts.s_nationkey = cc.c_nationkey
JOIN TotalOrders to ON to.o_custkey = cc.c_nationkey
WHERE rn.rank <= 5
ORDER BY rn.n_name, ts.total_cost DESC, cc.customer_count DESC;
