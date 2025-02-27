WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice,
           RANK() OVER (ORDER BY p.p_retailprice DESC) AS part_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), DiscountedOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_discounted
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
    HAVING SUM(l.l_discount) > 0.5
), NationalSummary AS (
    SELECT n.n_name, COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey 
    GROUP BY n.n_name
)
SELECT r.n_name, hs.p_name, hs.p_brand, ds.total_discounted,
       COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
       CASE 
           WHEN hs.part_rank <= 10 THEN 'Top Part'
           ELSE 'Regular Part'
       END AS part_category
FROM HighValueParts hs
JOIN DiscountedOrders ds ON ds.o_orderkey IN (SELECT DISTINCT o.o_orderkey 
                                               FROM orders o
                                               JOIN lineitem l ON o.o_orderkey = l.l_orderkey
                                               WHERE l.l_discount BETWEEN 0.05 AND 0.15)
LEFT JOIN RankedSuppliers rs ON hs.p_partkey = (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_suppkey = rs.s_suppkey 
      AND ps.ps_availqty > (SELECT AVG(ps2.ps_availqty) FROM partsupp ps2)
    LIMIT 1) 
JOIN NationalSummary ns ON ns.supplier_count > 5
WHERE hs.p_retailprice = (
    SELECT MAX(hs2.p_retailprice) 
    FROM HighValueParts hs2 
    WHERE hs2.part_rank <= 10 
      AND hs2.p_brand = hs.p_brand
) OR hs.p_container IS NULL
ORDER BY ns.total_supplycost DESC, ds.total_discounted DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
