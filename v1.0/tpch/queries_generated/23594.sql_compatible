
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS high_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY 
        o.o_orderkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
FilteredParts AS (
    SELECT 
        p.*,
        CASE 
            WHEN p.p_size IS NULL THEN 'Unknown Size'
            ELSE CAST(p.p_size AS VARCHAR(10))
        END AS size_info
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 10 AND 100
        AND (p.p_comment LIKE '%special%' OR p.p_comment IS NOT NULL)
),
SupplierParts AS (
    SELECT 
        ps.ps_suppkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    INNER JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    GROUP BY 
        ps.ps_suppkey
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) >= 100000
)

SELECT 
    n.n_name,
    rp.p_name,
    sp.total_supply_cost,
    ho.high_value
FROM 
    nation n
JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
JOIN 
    FilteredParts rp ON EXISTS(
        SELECT 1 
        FROM partsupp pp 
        WHERE pp.ps_partkey = rp.p_partkey AND pp.ps_suppkey = s.s_suppkey
    )
LEFT JOIN 
    HighValueOrders ho ON ho.o_orderkey = (SELECT o_orderkey FROM orders WHERE o_custkey = s.s_suppkey ORDER BY o_totalprice DESC LIMIT 1)
WHERE 
    sp.total_supply_cost IS NOT NULL
ORDER BY 
    n.n_name, sp.total_supply_cost DESC;
