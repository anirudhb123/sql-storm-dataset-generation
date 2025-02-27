WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > 1000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > 500
),
CustomerOrders AS (
    SELECT c.c_custkey, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
PartAvailability AS (
    SELECT p.p_partkey, p.p_name, 
           COALESCE(SUM(ps.ps_availqty), 0) AS total_available
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
),
TopProducts AS (
    SELECT p.p_partkey, p.p_name,
           ROW_NUMBER() OVER (ORDER BY pa.total_available DESC) AS rank
    FROM partavailability pa
    JOIN part p ON pa.p_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT s.s_suppkey, s.s_name, MAX(ps.ps_supplycost) AS max_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_suppkey, s.s_name
)
SELECT 
    r.r_name AS region,
    n.n_name AS nation,
    c.c_name AS customer,
    SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    STRING_AGG(DISTINCT sp.s_name, ', ') AS suppliers,
    MAX(sp.max_supply_cost) AS max_supplier_cost,
    AVG(co.total_spent) AS avg_customer_spending
FROM lineitem lo
JOIN orders o ON lo.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN HighValueSuppliers sp ON sp.s_suppkey = lo.l_suppkey
LEFT JOIN CustomerOrders co ON co.c_custkey = c.c_custkey
JOIN TopProducts tp ON tp.p_partkey = lo.l_partkey
WHERE o.o_orderstatus = 'O'
AND lo.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY r.r_name, n.n_name, c.c_name
HAVING SUM(lo.l_extendedprice * (1 - lo.l_discount)) > 50000
ORDER BY total_revenue DESC;