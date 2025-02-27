WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
TotalLineItems AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_linenumber) AS total_lines
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey
),
PartSupplies AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty * ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        ps.ps_partkey
),
SupplierLineItems AS (
    SELECT 
        l.l_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1997-06-01' AND '1997-06-30'
    GROUP BY 
        l.l_suppkey
)
SELECT 
    r.s_suppkey,
    r.s_name,
    COALESCE(t.total_lines, 0) AS total_line_items,
    s.total_sales,
    s.total_quantity,
    p.total_supply_cost
FROM 
    RankedSuppliers r
LEFT JOIN 
    TotalLineItems t ON t.o_orderkey = (SELECT o.o_orderkey FROM orders o WHERE o.o_custkey = r.s_suppkey LIMIT 1)
LEFT JOIN 
    SupplierLineItems s ON r.s_suppkey = s.l_suppkey
LEFT JOIN 
    PartSupplies p ON p.ps_partkey = (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = r.s_suppkey LIMIT 1)
WHERE 
    r.rank = 1
ORDER BY 
    r.s_name;