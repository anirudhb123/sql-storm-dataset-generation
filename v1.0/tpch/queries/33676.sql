WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_acctbal, 1 AS level
    FROM supplier
    WHERE s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE s.s_acctbal > sh.s_acctbal
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 1000
),
LineItemStats AS (
    SELECT l.l_orderkey, COUNT(*) AS item_count, AVG(l.l_extendedprice) AS avg_price
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    p.p_retailprice,
    COALESCE(c.total_spent, 0) AS total_spent,
    COALESCE(l.item_count, 0) AS total_items,
    COALESCE(l.avg_price, 0) AS avg_item_price,
    CASE 
        WHEN s.s_acctbal IS NOT NULL THEN 'Active Supplier' 
        ELSE 'Inactive Supplier' 
    END AS supplier_status
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN CustomerOrders c ON s.s_nationkey = c.c_custkey
LEFT JOIN LineItemStats l ON l.l_orderkey = ps.ps_partkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
  AND p.p_size BETWEEN 10 AND 20
  AND s.s_acctbal IS NOT NULL
ORDER BY total_spent DESC, p.p_name
LIMIT 50;
