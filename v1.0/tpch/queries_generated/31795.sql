WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal > 3000

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal < sh.s_acctbal AND sh.level < 3
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, c.c_nationkey, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_nationkey
),
LineItemStats AS (
    SELECT l.l_partkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue, 
           RANK() OVER (PARTITION BY l.l_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM lineitem l
    WHERE l.l_shipdate >= '2022-01-01' AND l.l_shipdate < '2023-01-01'
    GROUP BY l.l_partkey
)
SELECT 
    p.p_name,
    COALESCE(s.s_name, 'Unknown Supplier') AS supplier_name,
    r.r_name AS region_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    COALESCE(SUM(cs.total_spent), 0) AS total_customer_spending,
    COUNT(li.l_orderkey) AS total_orders,
    SUM(ls.revenue) AS total_line_item_revenue
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrders cs ON cs.c_nationkey = n.n_nationkey
LEFT JOIN lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN LineItemStats ls ON ls.l_partkey = p.p_partkey
WHERE p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_retailprice < 100.00)
GROUP BY p.p_name, s.s_name, r.r_name
HAVING SUM(ls.revenue) > 50000
ORDER BY total_customer_spending DESC, p.p_name
LIMIT 10;
