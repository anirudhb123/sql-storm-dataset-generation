WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 0 AS level
    FROM supplier
    WHERE s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
    
    UNION ALL
    
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_acctbal > sh.s_acctbal
),
LineItemStats AS (
    SELECT l_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS total_price, COUNT(*) AS item_count
    FROM lineitem
    WHERE l_shipdate >= '2023-01-01'
    GROUP BY l_orderkey
),
TopSuppliers AS (
    SELECT s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
    ORDER BY total_supply_cost DESC
    LIMIT 5
)
SELECT 
    r.r_name,
    SUM(ls.total_price) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    ts.s_name AS top_supplier,
    COUNT(DISTINCT sh.s_suppkey) AS total_sub_suppliers,
    RANK() OVER (PARTITION BY r.r_name ORDER BY SUM(ls.total_price) DESC) AS sales_rank
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN orders o ON o.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = n.n_nationkey LIMIT 1)
LEFT JOIN LineItemStats ls ON o.o_orderkey = ls.l_orderkey
LEFT JOIN TopSuppliers ts ON s.s_name = ts.s_name
LEFT JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
WHERE r.r_name IS NOT NULL
AND (ls.total_price IS NOT NULL OR sh.s_supplycost IS NULL)
GROUP BY r.r_name, ts.s_name
ORDER BY total_sales DESC;
