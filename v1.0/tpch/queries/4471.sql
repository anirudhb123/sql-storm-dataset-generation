
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 
           SUM(ps.ps_availqty) AS total_available_quantity,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),

OrdersSummary AS (
    SELECT o.o_orderkey, o.o_custkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(l.l_orderkey) AS total_lines
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_custkey
),

CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),

RevenueRanked AS (
    SELECT os.o_orderkey, os.total_revenue, 
           RANK() OVER (ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM OrdersSummary os
)

SELECT r.r_name,
       COUNT(DISTINCT c.c_custkey) AS customer_count,
       SUM(sd.total_available_quantity) AS total_available_parts,
       AVG(sd.avg_supply_cost) AS average_supply_cost,
       COALESCE(MAX(rr.total_revenue), 0) AS highest_order_revenue
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN SupplierDetails sd ON s.s_suppkey = sd.s_suppkey
LEFT JOIN CustomerOrders c ON n.n_nationkey = c.c_custkey
LEFT JOIN RevenueRanked rr ON rr.o_orderkey IN (SELECT o.o_orderkey
                                                 FROM orders o
                                                 WHERE o.o_custkey = c.c_custkey)
GROUP BY r.r_name
HAVING COUNT(DISTINCT c.c_custkey) > 10
ORDER BY r.r_name;
