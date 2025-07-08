
WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_acctbal,
        n.n_name AS nation,
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk,
        s.s_suppkey
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        s_name,
        s_acctbal,
        nation,
        s_suppkey
    FROM 
        RankedSuppliers
    WHERE 
        rnk <= 3
),
CombinedDetails AS (
    SELECT 
        p.p_name,
        ps.ps_supplycost,
        ts.s_name,
        ts.nation,
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
    GROUP BY 
        p.p_name, ps.ps_supplycost, ts.s_name, ts.nation, o.o_orderkey
)
SELECT 
    c.nation,
    LISTAGG(CONCAT(c.s_name, ' (', c.order_count, ' orders)')) WITHIN GROUP (ORDER BY c.s_name) AS supplier_details,
    SUM(c.total_sales) AS total_sales_value
FROM 
    CombinedDetails c
GROUP BY 
    c.nation
ORDER BY 
    total_sales_value DESC;
