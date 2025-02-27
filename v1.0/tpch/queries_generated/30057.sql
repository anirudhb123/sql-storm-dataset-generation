WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_suppkey, s_name, s_nationkey, s_acctbal, s_comment, 1 AS level
    FROM supplier
    WHERE s_acctbal > 5000
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, s.s_comment, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_suppkey
    WHERE s.s_acctbal > 10000
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING SUM(s.s_acctbal) > 100000
),
FilteredOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus, o.o_custkey,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM orders o
    WHERE o.o_orderstatus IN ('O', 'F')
)
SELECT 
    p.p_name,
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_sales,
    AVG(li.l_quantity) AS average_quantity,
    CASE 
        WHEN SUM(li.l_discount) > 0.1 THEN 'Discounted'
        ELSE 'Regular Price'
    END AS price_category,
    r.r_name AS region,
    n.n_name AS nation,
    SUM(COALESCE(s.s_acctbal, 0)) AS total_supplier_balance
FROM part p
JOIN lineitem li ON p.p_partkey = li.l_partkey
LEFT JOIN orders o ON li.l_orderkey = o.o_orderkey
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
LEFT JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN SupplierHierarchy sh ON sh.s_nationkey = n.n_nationkey
LEFT JOIN TopNations tn ON tn.n_nationkey = n.n_nationkey
LEFT JOIN supplier s ON s.s_nationkey = n.n_nationkey
WHERE li.l_shipdate > '2022-01-01'
GROUP BY p.p_name, r.r_name, n.n_name
HAVING COUNT(DISTINCT li.l_orderkey) > 5 AND SUM(li.l_extendedprice) IS NOT NULL
ORDER BY total_sales DESC, p.p_name;
