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
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rank
    FROM part p
    WHERE p.p_name LIKE '%steel%'
),
TopParts AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.p_mfgr, 
        rp.p_brand, 
        rp.p_type, 
        rp.p_size, 
        rp.p_container, 
        rp.p_retailprice, 
        rp.p_comment
    FROM RankedParts rp
    WHERE rp.rank <= 5
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate
)
SELECT 
    tp.p_partkey, 
    tp.p_name, 
    tp.p_retailprice, 
    co.c_custkey, 
    co.c_name, 
    co.total_spent
FROM TopParts tp
JOIN CustomerOrders co ON tp.p_name LIKE '%' || co.c_name || '%'
ORDER BY tp.p_type, co.total_spent DESC;
