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
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
), OrderSummary AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2022-01-01' AND o.o_orderdate < '2022-12-31'
    GROUP BY 
        o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
)
SELECT 
    c.c_custkey,
    c.c_name,
    os.total_sales,
    os.order_count,
    r.r_name AS region,
    rs.s_name AS top_supplier
FROM 
    customer c
JOIN 
    OrderSummary os ON c.c_custkey = os.o_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN 
    RankedSuppliers rs ON rs.rank = 1 AND rs.nation_name = n.n_name
JOIN 
    HighValueParts hvp ON hvp.ps_partkey IN (SELECT ps_partkey FROM partsupp WHERE ps_supplycost > 0)
ORDER BY 
    os.total_sales DESC, 
    c.c_name;
