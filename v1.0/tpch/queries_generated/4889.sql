WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        AVG(ps.ps_supplycost) < 50.00
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_partkey) AS distinct_parts
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '2022-01-01' 
        AND o.o_orderdate <= DATE '2022-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    hs.s_name AS high_value_supplier,
    hp.p_name AS part_name,
    od.total_sales,
    od.distinct_parts
FROM 
    RankedSuppliers rs
LEFT JOIN 
    supplier hs ON rs.s_suppkey = hs.s_suppkey
JOIN 
    nation n ON hs.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueParts hp ON hs.s_suppkey = (SELECT ps.ps_suppkey FROM partsupp ps WHERE ps.ps_partkey = hp.p_partkey LIMIT 1)
JOIN 
    OrderDetails od ON od.o_orderkey IN (
        SELECT o.o_orderkey 
        FROM orders o 
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey 
        WHERE l.l_partkey = hp.p_partkey
    )
WHERE 
    rs.rn = 1
AND 
    hs.s_acctbal IS NOT NULL
ORDER BY 
    total_sales DESC, region_name, high_value_supplier;
