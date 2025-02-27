WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), FilteredParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_type, 
        p.p_size, 
        p.p_container, 
        p.p_retailprice, 
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_size IN (1, 2, 3) AND 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
), OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_returnflag = 'N'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    r.r_name AS region_name, 
    SUM(od.total_revenue) AS total_revenue_generated,
    COUNT(DISTINCT fs.s_suppkey) AS unique_suppliers,
    COUNT(DISTINCT fp.p_partkey) AS unique_parts
FROM 
    RankedSuppliers fs
JOIN 
    FilteredParts fp ON fs.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = fp.p_partkey)
JOIN 
    nation n ON fs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    OrderDetails od ON od.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue_generated DESC;
