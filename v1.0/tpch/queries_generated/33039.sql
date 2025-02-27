WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 1 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier) -- Only suppliers above average balance
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey  -- Build hierarchy based on nation
),
TopParts AS (
    SELECT p.*, 
           SUM(ps.ps_supplycost) AS total_supplycost,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rank
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, p.p_size, p.p_container, p.p_retailprice, p.p_comment
),
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COUNT(o.o_orderkey) > 5 -- Customers with more than 5 orders
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    COUNT(DISTINCT sh.s_suppkey) AS supplier_count,
    AVG(co.order_count) AS average_orders_per_customer,
    MAX(tp.total_supplycost) AS max_supply_cost_part
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT OUTER JOIN SupplierHierarchy sh ON n.n_nationkey = sh.s_nationkey
LEFT JOIN CustomerOrders co ON n.n_nationkey = (SELECT n2.n_nationkey FROM nation n2 WHERE n2.n_nationkey = n.n_nationkey LIMIT 1)
JOIN TopParts tp ON tp.rank <= 3 -- Top 3 parts per brand
GROUP BY r.r_name
HAVING COUNT(DISTINCT n.n_nationkey) > 1
ORDER BY region_name;
