WITH SupplierSummary AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
), CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), LineItemAnalysis AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_shipdate DESC) AS rn
    FROM lineitem l
    WHERE l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY l.l_orderkey
)
SELECT 
    cs.c_name, 
    cs.order_count, 
    cs.total_spent, 
    ss.total_supply_value,
    la.revenue
FROM CustomerOrders cs
LEFT JOIN SupplierSummary ss ON ss.total_supply_value > 10000
LEFT JOIN LineItemAnalysis la ON la.rn = 1 
WHERE cs.order_count > 5 AND cs.total_spent IS NOT NULL 
ORDER BY cs.total_spent DESC, ss.total_supply_value
LIMIT 50;
