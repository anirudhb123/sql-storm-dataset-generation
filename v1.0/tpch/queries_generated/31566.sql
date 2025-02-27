WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT co.c_custkey, co.c_name, l.o_orderkey, l.o_orderdate, l.o_totalprice
    FROM CustomerOrders co
    JOIN orders l ON co.c_custkey = l.o_custkey
    WHERE l.o_orderdate > co.o_orderdate
),
TotalRevenuePerNation AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS total_revenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name
),
SupplierPartDetails AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_availqty > (SELECT AVG(ps2.ps_availqty)
                             FROM partsupp ps2
                             WHERE ps2.ps_partkey = ps.ps_partkey)
)
SELECT 
    c.c_name AS customer_name,
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_spent,
    COUNT(DISTINCT s.s_suppkey) AS total_suppliers,
    MAX(ps.ps_supplycost) AS max_supply_cost,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', ps.ps_availqty, ' available)'), ', ') AS part_details
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN SupplierPartDetails ps ON ps.s_suppkey = c.c_custkey -- assuming `c.c_custkey` relates to suppliers
LEFT JOIN part p ON ps.p_partkey = p.p_partkey
GROUP BY c.c_name, n.n_name
HAVING SUM(o.o_totalprice) IS NOT NULL AND COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_spent DESC;
