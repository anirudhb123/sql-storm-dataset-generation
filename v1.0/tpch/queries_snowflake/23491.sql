
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice > 100.00 THEN 'High'
            WHEN p.p_retailprice BETWEEN 50.00 AND 100.00 THEN 'Medium'
            ELSE 'Low'
        END AS price_category
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        ps.ps_supplycost,
        rp.price_category
    FROM 
        partsupp ps
    JOIN 
        HighValueParts rp ON ps.ps_partkey = rp.p_partkey
    WHERE 
        ps.ps_supplycost < (
            SELECT 
                AVG(ps2.ps_supplycost) 
            FROM 
                partsupp ps2 
            WHERE 
                ps2.ps_partkey = ps.ps_partkey
        )
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(sp.ps_supplycost) AS total_supply_cost,
    AVG(sp.ps_supplycost) AS avg_supply_cost,
    LISTAGG(DISTINCT hp.p_name, ', ') WITHIN GROUP (ORDER BY hp.p_name) AS high_value_parts
FROM 
    nation n 
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON s.s_suppkey = rs.s_suppkey
LEFT JOIN 
    SupplierParts sp ON rs.s_suppkey = sp.ps_suppkey
LEFT JOIN 
    OrderStats o ON rs.s_suppkey = o.o_orderkey
JOIN 
    HighValueParts hp ON sp.ps_partkey = hp.p_partkey
WHERE 
    rs.rn <= 5 
    AND o.total_revenue IS NOT NULL 
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 0
ORDER BY 
    total_orders DESC NULLS LAST;
