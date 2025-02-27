WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rank_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        COUNT(DISTINCT ps.ps_suppkey) AS sup_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_supplycost < 100.00 AND 
        ps.ps_availqty > 50
    GROUP BY 
        p.p_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
),
AggregatedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(l.l_orderkey) AS line_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '2023-01-01' AND 
        o.o_orderdate < '2024-01-01'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT hvp.p_partkey) AS high_value_parts_count,
    SUM(ao.total_sales) AS total_sales_sum,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM 
    RankedSuppliers s
JOIN 
    nation n ON s.nation_name = n.n_name
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueParts hvp ON hvp.ps_supplycost < 50.00
JOIN 
    AggregatedOrders ao ON ao.o_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = s.s_suppkey)
WHERE 
    s.rank_acctbal <= 5
GROUP BY 
    r.r_name
ORDER BY 
    total_sales_sum DESC;
