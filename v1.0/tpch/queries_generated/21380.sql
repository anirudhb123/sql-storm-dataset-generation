WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
LatestOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate,
           MAX(l.l_shipdate) OVER (PARTITION BY o.o_orderkey) AS max_shipdate
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'P')
),
FilteredParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           (SELECT COUNT(*) FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0) AS available_count
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 20
      AND p.p_container NOT IN ('BOX', 'CASE')
      AND (p.p_retailprice - (SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size = p.p_size)) > 50
),
NationsWithComments AS (
    SELECT n.n_nationkey, n.n_name, n.n_comment,
           (CASE WHEN n.n_comment IS NULL THEN 'No Comment' ELSE n.n_comment END) AS adjusted_comment
    FROM nation n
    WHERE n.n_regionkey = (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
)
SELECT F.p_partkey, F.p_name, F.p_retailprice, R.s_name, R.s_acctbal, 
       COALESCE(L.max_shipdate, '2000-01-01') AS last_ship_date,
       N.adjusted_comment,
       COUNT(DISTINCT O.o_orderkey) AS order_count
FROM FilteredParts F
LEFT JOIN RankedSuppliers R ON R.rnk <= 3
LEFT JOIN LatestOrders L ON L.o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_nationkey = (SELECT N.n_nationkey FROM NationsWithComments N WHERE N.n_name = 'USA'))
LEFT JOIN Orders O ON O.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = F.p_partkey)
WHERE F.available_count > 0
GROUP BY F.p_partkey, F.p_name, F.p_retailprice, R.s_name, R.s_acctbal, L.max_shipdate, N.adjusted_comment
ORDER BY F.p_retailprice DESC, order_count, last_ship_date;
