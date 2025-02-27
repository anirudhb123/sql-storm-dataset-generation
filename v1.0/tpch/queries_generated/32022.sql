WITH RECURSIVE RecentOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey
    FROM orders o
    WHERE o.o_orderdate >= DATE '2021-01-01'
    
    UNION ALL
    
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, o.o_custkey
    FROM orders o
    JOIN RecentOrders ro ON o.o_orderkey = ro.o_orderkey + 1
)
, SupplierParts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, s.s_name, ps.ps_supplycost
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
, CustomerStats AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS number_of_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank,
    r.r_name AS region_name,
    cs.total_spent,
    CASE 
        WHEN cs.total_spent IS NULL THEN 'No Orders'
        ELSE 'Orders placed'
    END AS order_status
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN supplierparts sp ON p.p_partkey = sp.ps_partkey
LEFT JOIN customer c ON sp.ps_suppkey = c.c_nationkey
LEFT JOIN region r ON c.c_nationkey = r.r_regionkey
LEFT JOIN CustomerStats cs ON c.c_custkey = cs.c_custkey
WHERE p.p_retailprice > 100
AND l.l_shipdate BETWEEN DATE '2021-01-01' AND DATE '2023-12-31'
GROUP BY p.p_name, r.r_name, cs.total_spent
HAVING COUNT(DISTINCT l.l_orderkey) > 5
ORDER BY total_revenue DESC
LIMIT 10;
