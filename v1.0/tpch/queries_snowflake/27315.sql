WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type, 
           p.p_size, p.p_container, p.p_retailprice, p.p_comment,
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size > 10 AND p.p_retailprice BETWEEN 100.00 AND 500.00
),
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           s.s_comment, n.n_name AS nation_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 5000.00
),
OrderSummary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY o.o_orderkey
)
SELECT rp.p_name, rp.p_brand, rp.p_retailprice, 
       sd.s_name, sd.nation_name, os.total_revenue
FROM RankedParts rp
JOIN SupplierDetails sd ON sd.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    WHERE ps.ps_partkey = rp.p_partkey 
    AND ps.ps_availqty > 0
    )
JOIN OrderSummary os ON os.o_orderkey IN (
    SELECT l.l_orderkey 
    FROM lineitem l 
    WHERE l.l_partkey = rp.p_partkey
)
WHERE rp.rn <= 5
ORDER BY rp.p_brand, os.total_revenue DESC;