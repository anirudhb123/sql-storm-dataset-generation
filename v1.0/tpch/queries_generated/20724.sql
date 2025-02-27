WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal * (1 + COALESCE(NULLIF(ROUND(RAND() * 0.1, 2), 0), 0.01)) AS level
    FROM supplier s
    INNER JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_totalprice, SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(li.l_extendedprice * (1 - li.l_discount)) DESC) AS order_rank
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY o.o_orderkey, o.o_totalprice
),
NationStats AS (
    SELECT n.n_nationkey, n.n_name, COUNT(s.s_suppkey) AS supplier_count,
           AVG(s.s_acctbal) AS average_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_nationkey, n.n_name
    HAVING COUNT(s.s_suppkey) >= 1
)
SELECT ps.ps_partkey, p.p_name, ns.n_name, ns.average_acctbal, oh.o_totalprice,
       CASE 
           WHEN ns.average_acctbal > 1000 THEN 'High'
           WHEN ns.average_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
           ELSE 'Low' 
       END AS acctbal_category,
       SUM(CASE WHEN li.l_returnflag = 'Y' THEN li.l_quantity ELSE 0 END) AS total_returned_quantity
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN NationStats ns ON s.s_nationkey = ns.n_nationkey
LEFT JOIN OrderDetails oh ON oh.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'F' LIMIT 1)
LEFT JOIN lineitem li ON li.l_partkey = p.p_partkey
GROUP BY ps.ps_partkey, p.p_name, ns.n_name, ns.average_acctbal, oh.o_totalprice
HAVING SUM(li.l_quantity) > 0 OR ns.average_acctbal IS NULL
ORDER BY ns.n_name, acctbal_category DESC, total_returned_quantity DESC;
