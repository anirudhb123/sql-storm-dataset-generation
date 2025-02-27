WITH RECURSIVE TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal
    FROM supplier s
    JOIN TopSuppliers ts ON s.s_acctbal > ts.s_acctbal
)
, RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) as price_rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
)
SELECT 
    n.n_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS total_returned_quantity,
    AVG(o.o_totalprice) as avg_order_price,
    STRING_AGG(DISTINCT CONCAT(p.p_name, ' (', s.s_name, ')'), ', ') AS part_supplier_details
FROM nation n
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN RankedParts p ON ps.ps_partkey = p.p_partkey AND p.price_rank <= 5
LEFT JOIN lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN orders o ON o.o_orderkey = l.l_orderkey 
LEFT JOIN customer c ON c.c_custkey = o.o_custkey
WHERE n.n_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name LIKE '%land%')
AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY n.n_name
HAVING SUM(l.l_quantity) > 1000
ORDER BY total_customers DESC;