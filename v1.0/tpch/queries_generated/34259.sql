WITH RECURSIVE SupplyChain AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, ps.ps_availqty, 0 AS depth
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, sc.ps_partkey, sc.ps_availqty, depth + 1
    FROM SupplyChain sc
    JOIN partsupp ps ON sc.ps_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE ps.ps_availqty > 0 AND depth < 10
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY c.c_custkey, c.c_name
    HAVING total_orders > 5
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING total_supplycost > 10000
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(ss.s_name, 'No Supplier') AS supplier_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) DESC) AS revenue_rank
FROM CustomerOrders c
LEFT JOIN orders o ON o.o_custkey = c.c_custkey
LEFT JOIN lineitem l ON l.l_orderkey = o.o_orderkey
LEFT JOIN TopSuppliers ss ON l.l_suppkey = ss.s_suppkey
LEFT JOIN SupplyChain sc ON ss.s_suppkey = sc.s_suppkey
WHERE COALESCE(ss.s_name, 'No Supplier') != 'No Supplier' OR o.o_orderstatus = 'O'
GROUP BY c.c_custkey, c.c_name, ss.s_name
HAVING SUM(l.l_extendedprice) > 1000
ORDER BY total_revenue DESC NULLS LAST
LIMIT 100;
