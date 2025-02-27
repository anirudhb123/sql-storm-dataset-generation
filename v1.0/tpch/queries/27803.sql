WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment, 
        DENSE_RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
),
PartSuppliers AS (
    SELECT 
        rp.p_partkey,
        rp.p_name,
        rp.p_retailprice,
        s.s_name AS supplier_name,
        s.s_nationkey,
        COUNT(ps.ps_availqty) AS available_quantity
    FROM RankedParts rp
    JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE rp.price_rank <= 5
    GROUP BY rp.p_partkey, rp.p_name, rp.p_retailprice, s.s_name, s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value,
        c.c_name,
        c.c_mktsegment
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    GROUP BY o.o_orderkey, o.o_custkey, c.c_name, c.c_mktsegment
)
SELECT 
    ps.p_name AS part_name,
    ps.supplier_name,
    ps.p_retailprice,
    co.c_name AS customer_name,
    co.total_value
FROM PartSuppliers ps
JOIN CustomerOrders co ON ps.p_partkey IN (
    SELECT l.l_partkey 
    FROM lineitem l 
    JOIN orders o ON l.l_orderkey = o.o_orderkey 
    WHERE o.o_orderstatus = 'O'
)
ORDER BY ps.p_retailprice DESC, co.total_value DESC
LIMIT 10;
