WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice, 
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) as rank
    FROM 
        part p
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey,
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        total_spent > 1000
)
SELECT 
    rp.p_name, 
    rp.p_retailprice, 
    fs.s_name, 
    fo.c_name AS customer_name, 
    fo.total_spent
FROM 
    RankedParts rp
JOIN 
    FilteredSuppliers fs ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = fs.s_suppkey)
JOIN 
    CustomerOrders fo ON fo.c_custkey IN (SELECT o.o_custkey FROM orders o JOIN lineitem l ON o.o_orderkey = l.l_orderkey WHERE l.l_partkey = rp.p_partkey)
WHERE 
    rp.rank <= 3
ORDER BY 
    rp.p_brand, rp.p_retailprice DESC, fo.total_spent DESC;
