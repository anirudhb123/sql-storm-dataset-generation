WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, 1 AS lvl
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, s.n_nationkey, sh.lvl + 1 
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.n_nationkey = sh.n_nationkey
    WHERE s.s_acctbal < sh.s_acctbal
),
LowPriceParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice ASC) AS rn
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
HighVolumeOrders AS (
    SELECT o.o_orderkey, SUM(l.l_quantity) AS total_quantity
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_quantity) > (SELECT AVG(SUM(l2.l_quantity)) FROM lineitem l2 GROUP BY l2.l_orderkey)
),
NationsWithComments AS (
    SELECT n.n_nationkey, n.n_name, COALESCE(NULLIF(n.n_comment, ''), 'No Comment') AS comment
    FROM nation n
)
SELECT DISTINCT
    sh.s_suppkey,
    sh.s_name,
    np.n_name,
    pp.p_name,
    pp.p_retailprice,
    lo.total_quantity,
    CASE
        WHEN pp.p_retailprice < 20 THEN 'Budget'
        WHEN pp.p_retailprice BETWEEN 20 AND 50 THEN 'Midrange'
        ELSE 'Luxury'
    END AS price_category,
    p.p_comment || ' | ' || COALESCE(nw.comment, 'Unknown') AS combined_comment
FROM SupplierHierarchy sh
JOIN NationsWithComments nw ON sh.n_nationkey = nw.n_nationkey
LEFT JOIN LowPriceParts pp ON pp.rn = 1
INNER JOIN HighVolumeOrders lo ON lo.o_orderkey = (SELECT o_orderkey FROM orders WHERE o_custkey = sh.s_suppkey LIMIT 1)
LEFT JOIN supplier s ON s.s_suppkey = sh.s_suppkey
WHERE pp.p_retailprice IS NOT NULL
ORDER BY price_category ASC, pp.p_retailprice DESC, sh.s_name;
