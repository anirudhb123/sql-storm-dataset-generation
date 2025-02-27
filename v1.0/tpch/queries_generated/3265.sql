WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        n.n_name
    FROM 
        RankedSuppliers s
    JOIN 
        nation n ON s.s_suppkey = n.n_nationkey
    WHERE 
        s.rn <= 3
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        AVG(ps.ps_supplycost) AS avg_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(DISTINCT l.l_linenumber) AS total_lineitems,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    ts.s_name AS supplier_name,
    os.total_lineitems,
    os.total_revenue,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue' 
        ELSE CONCAT('Revenue: $', CAST(os.total_revenue AS VARCHAR))
    END AS revenue_message
FROM 
    PartDetails pd
LEFT JOIN 
    TopSuppliers ts ON pd.p_partkey IN (SELECT ps.ps_partkey FROM partsupp ps WHERE ps.ps_suppkey = ts.s_suppkey)
LEFT JOIN 
    OrderSummary os ON os.total_lineitems > 0
WHERE 
    pd.avg_supplycost > (
        SELECT 
            AVG(ps_supplycost) 
            FROM partsupp
    )
ORDER BY 
    pd.p_retailprice DESC, ts.s_name, os.total_revenue DESC;
