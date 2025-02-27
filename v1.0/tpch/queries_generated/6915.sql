WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ps.ps_supplycost,
        (p.p_retailprice - ps.ps_supplycost) AS profit_margin
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > 100.00
), OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.nation_name,
    SUM(od.total_revenue) AS total_revenue,
    COUNT(DISTINCT p.p_partkey) AS unique_parts_sold,
    AVG(p.profit_margin) AS avg_profit_margin
FROM 
    RankedSuppliers r
JOIN 
    HighValueParts p ON r.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = p.p_partkey)
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    OrderDetails od ON l.l_orderkey = od.o_orderkey
GROUP BY 
    r.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
