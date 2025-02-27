
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        p.p_name, 
        ROW_NUMBER() OVER (PARTITION BY p.p_name ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
), FilteredNations AS (
    SELECT 
        n.n_nationkey, 
        n.n_name
    FROM 
        nation n
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name LIKE 'Eu%'
), OrderStatistics AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        COUNT(l.l_orderkey) AS line_item_count, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    n.n_name AS nation_name, 
    ss.p_name AS part_name, 
    ss.s_name AS supplier_name, 
    os.total_revenue, 
    os.line_item_count
FROM 
    RankedSuppliers ss
JOIN 
    FilteredNations n ON ss.s_suppkey IN (SELECT s.s_suppkey FROM supplier s WHERE s.s_nationkey = n.n_nationkey)
JOIN 
    OrderStatistics os ON ss.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_name = ss.p_name))
WHERE 
    ss.rn = 1
ORDER BY 
    os.total_revenue DESC, 
    n.n_name, 
    ss.p_name;
