WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.n_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_comment NOT LIKE '%tax%' AND 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        total_supply_value > (SELECT AVG(ps_supplycost * ps_availqty) FROM partsupp ps)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O' 
    GROUP BY 
        o.o_orderkey
),
NULLSafetyCheck AS (
    SELECT 
        c.c_name,
        COALESCE(MAX(os.total_revenue), 0) AS max_revenue,
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN 
        OrderSummary os ON o.o_orderkey = os.o_orderkey
    LEFT JOIN 
        supplier s ON c.c_nationkey = s.s_nationkey
    GROUP BY 
        c.c_name
)
SELECT 
    h.p_partkey,
    h.p_name,
    r.s_name,
    ns.max_revenue,
    ns.unique_suppliers
FROM 
    HighValueParts h
FULL OUTER JOIN 
    RankedSuppliers r ON h.p_partkey = r.s_suppkey
FULL OUTER JOIN 
    NULLSafetyCheck ns ON r.s_name IS NULL OR ns.unique_suppliers > 0
WHERE 
    (r.rn <= 3 OR r.rn IS NULL)
    AND (h.total_supply_value IS NOT NULL OR ns.unique_suppliers IS NOT NULL)
ORDER BY 
    ns.max_revenue DESC, h.p_partkey;
