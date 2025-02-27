WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_mfgr, 
           p.p_brand, 
           p.p_type, 
           p.p_size, 
           p.p_container, 
           p.p_retailprice, 
           p.p_comment, 
           ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) as rank
    FROM part p
),
SupplierDetails AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           s.s_nationkey, 
           s.s_phone, 
           s.s_acctbal, 
           s.s_comment, 
           SUBSTRING(s.s_comment, 1, 30) as short_comment
    FROM supplier s
),
CustomerOrders AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_totalprice, 
           o.o_orderdate, 
           c.c_name, 
           c.c_mktsegment,
           CASE 
               WHEN c.c_acctbal > 1000 THEN 'High'
               WHEN c.c_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
               ELSE 'Low' 
           END as acctbal_category
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
),
AggregatedLineItems AS (
    SELECT l.l_partkey, 
           SUM(l.l_quantity) as total_quantity, 
           AVG(l.l_extendedprice) as avg_price
    FROM lineitem l
    GROUP BY l.l_partkey
)
SELECT rp.p_name, 
       rp.p_brand, 
       sd.s_name, 
       sd.short_comment, 
       co.o_orderkey, 
       co.o_totalprice, 
       co.acctbal_category, 
       ali.total_quantity, 
       ali.avg_price
FROM RankedParts rp
JOIN SupplierDetails sd ON rp.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp WHERE ps.ps_partkey = rp.p_partkey) LIMIT 1)
JOIN CustomerOrders co ON co.o_orderkey IN (SELECT o.o_orderkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = rp.p_partkey)
JOIN AggregatedLineItems ali ON ali.l_partkey = rp.p_partkey
WHERE rp.rank <= 5
ORDER BY rp.p_type, co.o_totalprice DESC;
