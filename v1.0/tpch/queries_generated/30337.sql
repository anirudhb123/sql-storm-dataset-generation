WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS depth
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Base case: suppliers with above-average account balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.depth + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.depth < 3 -- Limiting recursion to a depth of 3 
),
PopularParts AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) as total_availqty,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY SUM(ps.ps_availqty) DESC) AS rn
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
CustomerOrders AS (
    SELECT c.c_custkey, COUNT(DISTINCT o.o_orderkey) AS order_count,
           SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' -- Only considering orders with a status of 'O'
    GROUP BY c.c_custkey
),
OrderStats AS (
    SELECT c.c_custkey, c.c_name, COALESCE(co.order_count, 0) AS order_count,
           COALESCE(co.total_spent, 0) AS total_spent,
           ROW_NUMBER() OVER (ORDER BY COALESCE(co.total_spent, 0) DESC) AS cust_rank
    FROM customer c
    LEFT JOIN CustomerOrders co ON c.c_custkey = co.c_custkey
)
SELECT s.s_name, p.p_name, COUNT(DISTINCT o.o_orderkey) AS total_orders,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
       CASE WHEN ph.depth IS NULL THEN 'Tier 1' ELSE 'Tier 2+' END AS supplier_tier,
       r.r_name
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN SupplierHierarchy ph ON s.s_suppkey = ph.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 100
GROUP BY s.s_name, p.p_name, ph.depth, r.r_name
HAVING COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY total_orders DESC, total_revenue DESC;
