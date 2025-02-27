WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_type, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_size BETWEEN 10 AND 30
), 
SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM supplier s
    WHERE s.s_acctbal > 5000
), 
CustomerOrders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE c.c_mktsegment = 'BUILDING' AND o.o_orderdate >= '2022-01-01'
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderstatus
), 
FinalReport AS (
    SELECT rp.p_name, rp.p_brand, sd.s_name, sd.s_acctbal, co.c_name, co.total_value
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    JOIN CustomerOrders co ON co.o_orderkey IN (
        SELECT o.o_orderkey
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        WHERE l.l_partkey = rp.p_partkey
    )
    WHERE rp.rank <= 5 AND sd.supplier_rank <= 10
)
SELECT p_name, p_brand, s_name, s_acctbal, c_name, total_value
FROM FinalReport
ORDER BY total_value DESC;
