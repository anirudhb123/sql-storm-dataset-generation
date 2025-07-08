
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        p.p_comment,
        ps.ps_availqty,
        ps.ps_supplycost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        ps.ps_availqty > 100
),
ExcessiveTransactions AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey
    HAVING 
        COUNT(l.l_orderkey) > 5
),
NationComparison AS (
    SELECT 
        n.n_name,
        SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
        SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_quantity ELSE 0 END) AS sold_quantity
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        lineitem l ON s.s_suppkey = l.l_suppkey
    GROUP BY 
        n.n_name
)
SELECT 
    pd.p_partkey,
    pd.p_name,
    pd.p_retailprice,
    pd.ps_availqty,
    ns.n_name AS supplier_nation,
    ns.returned_quantity,
    ns.sold_quantity,
    rs.s_name AS top_supplier,
    rs.s_acctbal AS top_supplier_balance
FROM 
    PartDetails pd
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1 AND pd.ps_supplycost = (SELECT MIN(ps_supplycost) FROM partsupp WHERE ps_partkey = pd.p_partkey)
LEFT JOIN 
    NationComparison ns ON EXISTS (SELECT 1 FROM part p WHERE p.p_name LIKE '%' || ns.n_name || '%' AND p.p_partkey = pd.p_partkey)
WHERE 
    pd.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
ORDER BY 
    pd.p_retailprice DESC
LIMIT 10;
