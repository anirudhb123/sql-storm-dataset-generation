WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
AvailableParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    p.p_name,
    ap.total_available,
    os.total_revenue,
    rs.nation_name,
    rs.s_name,
    CASE 
        WHEN os.total_revenue IS NULL THEN 'No Revenue'
        ELSE CAST(os.avg_quantity AS VARCHAR)
    END AS avg_quantity_status
FROM 
    AvailableParts ap
LEFT JOIN 
    OrderSummary os ON ap.p_partkey = (SELECT ps.ps_partkey FROM partsupp ps ORDER BY ps.ps_availqty DESC LIMIT 1)
LEFT JOIN 
    RankedSuppliers rs ON rs.rn = 1
WHERE 
    ap.total_available > 1000
ORDER BY 
    total_cost DESC, 
    rs.nation_name;
