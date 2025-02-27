WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(ps.ps_supplycost) > 1000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate BETWEEN '2023-01-01' AND '2023-12-31'
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    COALESCE(sp.total_revenue, 0) AS total_revenue,
    COALESCE(sp.total_quantity, 0) AS total_quantity,
    COUNT(DISTINCT pv.p_partkey) AS unique_parts,
    MAX(s.s_acctbal) AS highest_supplier_balance,
    STRING_AGG(DISTINCT s.s_name, ', ') AS supplier_names
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey AND rs.rank <= 3
LEFT JOIN 
    HighValueParts pv ON pv.supplier_count > 0
LEFT JOIN 
    OrderSummary sp ON s.s_suppkey = sp.o_orderkey
WHERE 
    (r.r_name IS NOT NULL OR r.r_comment IS NOT NULL)
    AND (s.s_acctbal IS NULL OR s.s_acctbal > 100)
GROUP BY 
    r.r_name
ORDER BY 
    r.r_name ASC
FETCH FIRST 10 ROWS ONLY;
