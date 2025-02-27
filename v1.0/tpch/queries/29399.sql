WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_type, 
        p.p_retailprice, 
        p.p_comment, 
        RANK() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        COUNT(ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_address
    HAVING 
        COUNT(ps.ps_partkey) > 10
),
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        COUNT(l.l_orderkey) AS lineitem_count, 
        SUM(l.l_extendedprice) AS total_price
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(l.l_orderkey) > 5
)
SELECT 
    rp.p_name, 
    rp.p_brand, 
    rp.p_type, 
    rp.p_retailprice, 
    ts.s_name AS supplier_name, 
    ts.part_count AS supplier_part_count, 
    od.lineitem_count, 
    od.total_price
FROM 
    RankedParts rp
JOIN 
    TopSuppliers ts ON rp.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT l.l_orderkey FROM lineitem l WHERE l.l_partkey = rp.p_partkey)
WHERE 
    rp.price_rank <= 5
ORDER BY 
    rp.p_retailprice DESC;
