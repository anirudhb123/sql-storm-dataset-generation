WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE sh.level < 5
),
OrderAggregates AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= DATE '2023-01-01'
    GROUP BY o.o_orderkey
),
CustomerNations AS (
    SELECT DISTINCT c.c_nationkey, r.r_name
    FROM customer c
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
)
SELECT 
    p.p_name,
    p.p_brand,
    p.p_mfgr,
    AVG(s.s_acctbal) AS avg_acct_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COUNT(DISTINCT l.l_linenumber) AS lineitem_count,
    CASE 
        WHEN SUM(o.total_sales) IS NULL THEN 'No sales'
        ELSE SUM(o.total_sales)
    END AS total_sales,
    r.r_name AS customer_region
FROM part p
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
LEFT JOIN OrderAggregates o ON o.o_orderkey = ps.ps_suppkey
LEFT JOIN CustomerNations cn ON s.s_nationkey = cn.c_nationkey
LEFT JOIN region r ON cn.c_nationkey = r.r_regionkey
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size > 10)
GROUP BY p.p_partkey, r.r_name
HAVING AVG(s.s_acctbal) > 100.00 
ORDER BY total_sales DESC, avg_acct_balance ASC
LIMIT 100;
