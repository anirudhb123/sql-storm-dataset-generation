WITH RECURSIVE CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '2023-01-01'
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
    WHERE o.o_orderdate > co.o_orderdate
),
AverageOrderValue AS (
    SELECT c.c_custkey, c.c_name, AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_value DESC
    LIMIT 5
),
OrdersByRegion AS (
    SELECT r.r_name, SUM(o.o_totalprice) AS total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY r.r_name
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    av.avg_order_value,
    sr.r_name AS supplier_region,
    ts.s_name AS top_supplier_name,
    ts.total_supply_value
FROM CustomerOrders o
JOIN AverageOrderValue av ON o.c_custkey = av.c_custkey
LEFT JOIN OrdersByRegion sr ON sr.total_revenue > 100000
LEFT JOIN TopSuppliers ts ON ts.total_supply_value = (
    SELECT MAX(total_supply_value) 
    FROM TopSuppliers
)
WHERE o.o_totalprice IS NOT NULL
AND av.avg_order_value > 500 
ORDER BY o.o_orderdate DESC, c.c_name;
