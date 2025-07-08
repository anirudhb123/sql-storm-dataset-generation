WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
SupplierNation AS (
    SELECT s.s_suppkey, s.s_name, n.n_name
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
HighPriceParts AS (
    SELECT rp.p_partkey, rp.p_name, rp.p_retailprice, sn.n_name AS supplier_nation
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN SupplierNation sn ON ps.ps_suppkey = sn.s_suppkey
    WHERE rp.price_rank <= 10
),
CustomerOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate >= '1997-01-01'
)
SELECT hpp.p_name, hpp.p_retailprice, co.c_name, co.o_totalprice, co.o_orderdate, hpp.supplier_nation
FROM HighPriceParts hpp
JOIN CustomerOrders co ON hpp.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem l
    WHERE l.l_orderkey = co.o_orderkey
)
ORDER BY hpp.p_retailprice DESC, co.o_totalprice ASC;