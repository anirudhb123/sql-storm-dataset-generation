WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_retailprice IS NOT NULL
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL AND s.s_comment NOT LIKE '%obsolete%'
),
FrequentOrders AS (
    SELECT o.o_orderkey, 
           o.o_orderstatus, 
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATEADD(year, -1, GETDATE())
    GROUP BY o.o_orderkey, o.o_orderstatus
    HAVING COUNT(DISTINCT l.l_linenumber) > 10
),
FilteredNations AS (
    SELECT n.n_nationkey,
           n.n_name,
           n.n_regionkey 
    FROM nation n
    WHERE n.n_comment IS NOT NULL AND n.n_name NOT LIKE '%land%'
),
OuterJoinResults AS (
    SELECT r.r_name,
           COALESCE(SUM(CASE WHEN o.o_orderstatus = 'O' THEN l.l_extendedprice END), 0) AS total_outstanding,
           COUNT(DISTINCT c.c_custkey) AS total_customers
    FROM region r
    LEFT JOIN supplier s ON s.s_nationkey IN (SELECT fn.n_nationkey FROM FilteredNations fn)
    LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    LEFT JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE r.r_name IS NOT NULL
    GROUP BY r.r_name
)
SELECT r.r_name, 
       r.total_outstanding,
       p.p_name,
       p.p_brand,
       p.p_retailprice, 
       NULLIF(r.total_customers, 0) AS total_customers_safe,
       CASE 
           WHEN rp.rank = 1 THEN 'High Value Part'
           ELSE 'Standard Part'
       END AS part_category
FROM OuterJoinResults r
JOIN RankedParts rp ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > (SELECT AVG(ps_availqty) FROM partsupp WHERE ps_partkey = rp.p_partkey))
LEFT JOIN part p ON p.p_partkey = rp.p_partkey
ORDER BY r.total_outstanding DESC, p.p_retailprice DESC;
