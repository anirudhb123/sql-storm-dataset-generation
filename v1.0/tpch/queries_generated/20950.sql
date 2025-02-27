WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        p.p_size,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS rn
    FROM 
        part p
    WHERE 
        p.p_size IN (SELECT DISTINCT ps.ps_availqty FROM partsupp ps WHERE ps.ps_supplycost > (SELECT AVG(ps2.ps_supplycost) FROM partsupp ps2))
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(ps.ps_availqty) > 1000
), 
EligibleOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus NOT IN ('F', 'X') 
        AND l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
    HAVING 
        SUM(l.l_discount) < 0.05
)
SELECT 
    e.o_orderkey,
    e.total_order_value,
    p.p_name,
    s.s_name,
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count
FROM 
    EligibleOrders e
JOIN 
    lineitem l ON e.o_orderkey = l.l_orderkey
JOIN 
    RankedParts p ON l.l_partkey = p.p_partkey AND p.rn <= 5
JOIN 
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name IS NOT NULL OR e.total_order_value > 10000
GROUP BY 
    e.o_orderkey, e.total_order_value, p.p_name, s.s_name, r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 2
ORDER BY 
    e.total_order_value DESC,
    r.r_name ASC;
